//+------------------------------------------------------------------+
//|                                                    PSSignals.mqh |
//|                                   Copyright 2019, PSInvest Corp. |
//|                                          https://www.psinvest.eu |
//+------------------------------------------------------------------+
// Signals functions
#property copyright "Copyright 2019, PSInvest Corp."
#property link      "https://www.psinvest.eu"
#property version   "3.00"
#property strict
#include <FileLog.mqh>
#include <PSMarket.mqh>
#include <PSTrendDetector.mqh>

#define MAX_OPEN_SIGNAL_ID 22
#define MAX_CLOSE_SIGNAL_ID 14

class PSSignals
{
	public:
		PSSignals(CFileLog *fileLog, string symbol, int period, int signalOpenId, int signalCloseId);
		~PSSignals();
		bool IsInitialised();
		int Open();
		int Close();
		int GetMagicNumber();
		bool IsMagicNumberBelong(int magicNumber);
	private:
		CFileLog *_fileLog;
		PSTrendDetector *_trendDetector;
		string _symbol;
		int _period;

		bool _isInitialised;
		void CheckInputValues();

		int _signalOpenId;
		int _signalCloseId;

		int _lastBarOpenNum;
		int _lastBarCloseNum;
		bool IsNewBar(bool isOpen);

		int _lastCloseDirection;
		int _lastOpenDirection;

		int _magicNumber;
		int _maxMagicNumber;
		void BuildMagicNumber();
		
		int DuplicateCloseFilter(int currentDirection);

		int CheckAreSame(int highDirection, int currentDirection);
		int CheckAreSame(int highDirection, int currentDirection, int lowDirection);
		
		int DuplicateOpenFilter(int currentDirection);
		int DuplicateOpenFilter(int highDirection, int currentDirection);
		int DuplicateOpenFilter(int highDirection, int currentDirection, int lowDirection);
		
		int _nearOpenFilterBar;
		int _nearOpenFilterDirection;
		int NearOpenFilter(int currentDirection, int nearBar = 1);

		int ReverseSignal(int currentDirection);

		int _nearCloseFilterBar;
		int _nearCloseFilterDirection;
		int NearCloseFilter(int currentDirection, int nearBar = 1);

		int _lastSameCloseDirection;
		int LastSameCloseFilter(int currentDirection);
};

PSSignals::PSSignals(CFileLog *fileLog, string symbol, int period, int signalOpenId, int signalCloseId)
{
	_trendDetector = new PSTrendDetector(fileLog, symbol, period);

	_fileLog = fileLog;
	_symbol = symbol;
	_period = period;
	_signalOpenId = signalOpenId;
	_signalCloseId = signalCloseId;

	CheckInputValues();

	if (_isInitialised) 
	{
		BuildMagicNumber();
	}
		
	_lastBarOpenNum = 0;
	_lastOpenDirection = OP_NONE;
	
	_lastBarCloseNum = 0;
	_lastCloseDirection = OP_NONE;

	_nearOpenFilterBar = 0;
	_nearOpenFilterDirection = OP_NONE;

	_nearCloseFilterBar = 0;
	_nearCloseFilterDirection = OP_NONE;

	_lastSameCloseDirection = OP_NONE;
}

PSSignals::~PSSignals()
{
	delete _trendDetector;
}

void PSSignals::CheckInputValues()
{
	bool log = _fileLog != NULL;
	if (!log) {
		_fileLog.Error(StringConcatenate(__FUNCTION__, " FileLog must not be NULL!"));
	}
	
	bool trendDetector = _trendDetector.IsInitialised();
	if (!trendDetector) {
		_fileLog.Error(StringConcatenate(__FUNCTION__, " TrendDetector is not initialised!"));
	}

	bool symbol = IsSymbolValid(_symbol);
	if (!symbol) {
		_fileLog.Error(StringConcatenate(__FUNCTION__, " Symbol: ", _symbol, " is not valid by system!"));
	}

	bool period = IsTimeFrameValid(_period);
	if (!period) {
		_fileLog.Error(StringConcatenate(__FUNCTION__, " Time frame: ", _period, " is not valid by system!"));
	}

	bool signalOpen = _signalOpenId > 0 && _signalOpenId <= MAX_OPEN_SIGNAL_ID;
	if (!signalOpen) {
		_fileLog.Error(StringConcatenate(__FUNCTION__, " SignalOpenId: ", _signalOpenId, " must be from: 1 to ", MAX_OPEN_SIGNAL_ID));
	}

	bool signalClose = _signalCloseId > 0 && _signalCloseId <= MAX_CLOSE_SIGNAL_ID;
	if (!signalClose) {
		_fileLog.Error(StringConcatenate(__FUNCTION__, " SignalCloseId: ", _signalCloseId, " must be from: 1 to ", MAX_CLOSE_SIGNAL_ID));
	}

	_isInitialised = log && trendDetector && symbol && period && signalOpen && signalClose;

	if (!_isInitialised) 
	{
		_fileLog.Error(StringConcatenate(__FUNCTION__, " PSSignals is not initialised!"));
	}
	else
	{
		_fileLog.Info(StringConcatenate(__FUNCTION__, " PSSignals is initialised. Symbol: ", _symbol, ", Period (in minute): ", _period, 
			", Open signal Id: ", _signalOpenId, ", Signal close Id: ", _signalCloseId));
	}
}

bool PSSignals::IsInitialised()
{
	return _isInitialised;
}

void PSSignals::BuildMagicNumber()
{
	// int max is 2 147 483 647
	// 1 111 111 111
	//   | -  symbol
	//    | - period
	//     | | - signal open Id
	//        || - signal close
	//           ||| - ???

	int symbolId = GetSymbolIndex(_symbol);
	int periodId = GetTimeFrameIndex(_period);

	_magicNumber = 
		symbolId * 100000000 +
		periodId * 10000000 +
		_signalOpenId * 100000 +
		_signalCloseId * 1000;
	
	_maxMagicNumber = _magicNumber + 999;
}

int PSSignals::GetMagicNumber()
{
	return _magicNumber;
}

// @brief Check if magic number belong this object.
bool PSSignals::IsMagicNumberBelong(int magicNumber)
{
	return magicNumber >= _magicNumber && magicNumber <= _maxMagicNumber;
}

bool PSSignals::IsNewBar(bool isOpen)
{
	int currentBarNumber = iBars(_symbol, _period);

	// Process logics only if new bar is appaired.
	if (isOpen) 
	{
		if(currentBarNumber == _lastBarOpenNum)
		{
			return false;
		}

		_lastBarOpenNum = currentBarNumber;
	}
	else
	{
		if(currentBarNumber == _lastBarCloseNum)
		{
			return false;
		}

		_lastBarCloseNum = currentBarNumber;
	}

   return true;
}

// @brief Process open signals
// @return OP_NONE - isn't necessary any action, OP_BUY - open Buy orders, OP_SELL - open sell orders.
int PSSignals::Open()
{
	if (!IsNewBar(true)) {
		return OP_NONE;
	}

	switch (_signalOpenId)
	{
		// TODO: It must be refactoring. Signals are missmached.
		//case 3: return DuplicateOpenFilter(_trendDetector.CurrentCspLine());
		// TODO: It must be refactoring. Signals are missmached.
		//case 4: return DuplicateOpenFilter(_trendDetector.CurrentCollaps());
		// TODO: It must be refactoring. Small signals.
		//case 5: return DuplicateOpenFilter(_trendDetector.CurrentEnvelop());
		// TODO: It must be refactoring. Signals are missmached.
		//case 6: return DuplicateOpenFilter(_trendDetector.CurrentWpr());
		// TODO: It must be refactoring.
		//case 8: return DuplicateOpenFilter(_trendDetector.CurrentMA2());
		// TODO: It must be refactoring. Signals are mismatched.
		//case 12: return _trendDetector.CurrentDifMA();
		// TODO: It must be refactoring. Signals are too small.
		//case 14: return DuplicateOpenFilter(_trendDetector.CurrentInsideBar());
		// TODO: It must be refactoring. It doesn't send signals.
		//case 15: return _trendDetector.CurrentBUOVB_BEOVB();
		// It react slower than _trendDetector.CurrentT1Signal1(true);
		//case 17: return _trendDetector.CurrentT1Signal2(true);
		// TODO: It must be refactoring. Signals are mismatched.
		//case 18: return _trendDetector.CurrentT2Signal1();
		// TODO: It must be refactoring. Signals are mismatched.
		//case 27: return _trendDetector.CurrentSMACrossoverPullback();
		// TODO: It must be refactoring. Signals are mismatched.
		//case 31: return CheckAreSame(_trendDetector.HighStepMAStoch(), _trendDetector.CurrentExp14M(), _trendDetector.LowMA_M15());
		case 1: return DuplicateOpenFilter(_trendDetector.CurrentShip());
		case 2: return DuplicateOpenFilter(_trendDetector.HighMA3(), _trendDetector.CurrentMA3());
		case 3: return DuplicateOpenFilter(_trendDetector.CurrentWpr2()); // old 7
		case 4: return _trendDetector.CurrentMacd(true); // old 9
		case 5: return DuplicateOpenFilter(_trendDetector.CurrentSidus(true)); // old 10
		case 6: return NearOpenFilter(_trendDetector.CurrentSidusSafe(true), 3); // old 11
		case 7: return DuplicateOpenFilter(_trendDetector.CurrentZigZag()); // old 13
		case 8: return _trendDetector.CurrentT1Signal1(true); // old 17

		case 9: return _trendDetector.CurrentT2Signal2(); // old 19
		case 10: return NearOpenFilter(_trendDetector.CurrentT4Signal(), 5); // old 20
		case 11: return NearOpenFilter(_trendDetector.ASCT_RAVI(), 3); // old 21
		case 12: return _trendDetector.CurrentHLHBTrendCatcher(false, false); // old 22
		case 13: return _trendDetector.CurrentHLHBTrendCatcher(true, false); // old 23
		case 14: return _trendDetector.CurrentHLHBTrendCatcher(false, true); // old 24
		case 15: return _trendDetector.CurrentHLHBTrendCatcher(true, true); // old 25
		case 16: return NearOpenFilter(_trendDetector.CurrentSTBollingerRev(), 5); // old 26
		case 17: return _trendDetector.CurrentExp11M(); // old 28
		case 18: return CheckAreSame(_trendDetector.HighMA1(), _trendDetector.CurrentExp11M()); // old 29
		case 19: return CheckAreSame(_trendDetector.HighMAMANK(), _trendDetector.CurrentExp12M(), _trendDetector.LowMA_M15()); // old 30
		case 20: return CheckAreSame(_trendDetector.HighMA1(), _trendDetector.CurrentThreeTF1(), _trendDetector.LowMA_M15()); // old 32
		case 21: return NearOpenFilter(_trendDetector.The3Ducks(), 5); // old 33

		case MAX_OPEN_SIGNAL_ID: 
				return _trendDetector.Exp11(true);
		
		default: 
			return OP_NONE;
	}

	return OP_NONE;
}

// @brief Process close signals
// @return OP_NONE - no action necessary, OP_BUY - close Buy orders, OP_SELL - close sell orders.
int PSSignals::Close()
{
	if (!IsNewBar(false)) {
		return OP_NONE;
	}

	switch (_signalCloseId)
	{
		case 1: return NearCloseFilter(_trendDetector.CurrentThreeTF1(), 10);
		case 2: return NearCloseFilter(_trendDetector.HighMA3(), 10);
		case 3: return NearCloseFilter(_trendDetector.HighMAMANK(), 10);
		case 4: return NearCloseFilter(_trendDetector.HighStepMAStoch(), 10);
		case 5: return NearCloseFilter(_trendDetector.HighJ2JMA(), 10);
		case 6: return _trendDetector.CurrentMacd(false);
		case 7: return LastSameCloseFilter(_trendDetector.CurrentSidus(false));
		case 8: return LastSameCloseFilter(_trendDetector.CurrentSidusSafe(false));
		case 9: return DuplicateCloseFilter(_trendDetector.CurrentT1Signal1(false));
		case 10: return DuplicateCloseFilter(_trendDetector.CurrentT1Signal2(false));
		case 11: return DuplicateCloseFilter(_trendDetector.CurrentT4CloseSignal());
		case 12: return _trendDetector.CurrentExp11M();
		case 13: return ReverseSignal(_trendDetector.CurrentExp12M());
		case MAX_CLOSE_SIGNAL_ID: return _trendDetector.Exp11(false);

		default: 
			return OP_NONE;
	}

	return OP_NONE;
}

int PSSignals::LastSameCloseFilter(int currentDirection)
{	
	if (_lastSameCloseDirection != currentDirection) 
	{
		int result = _lastSameCloseDirection;
		_lastSameCloseDirection = currentDirection;

		return result;
	}

	return OP_NONE;
}

int PSSignals::ReverseSignal(int currentDirection)
{	
	if (currentDirection == OP_BUY) 
	{
		return OP_SELL;
	}

	if (currentDirection == OP_SELL) 
	{
		return OP_BUY;
	}
	
	return OP_NONE;
}

int PSSignals::DuplicateCloseFilter(int currentDirection)
{	
	if (currentDirection == OP_NONE) 
	{
		return OP_NONE;
	}
	
	if (_lastCloseDirection != currentDirection) 
	{
		int result = _lastCloseDirection;
		_lastCloseDirection = currentDirection;
		
		return result;
	}
	
	return OP_NONE;
}

int PSSignals::NearCloseFilter(int currentDirection, int nearBar = 1)
{	
	if (currentDirection == OP_NONE) 
	{
		return OP_NONE;
	}
	
	int currentBar = iBars(_symbol, _period);

	if (currentDirection == _nearCloseFilterDirection && (_nearCloseFilterBar + nearBar) >= currentBar ) 
	{
		return OP_NONE;
	}

	_nearCloseFilterBar = currentBar;
	_nearCloseFilterDirection = currentDirection;
	
	return _nearCloseFilterDirection;
}

int PSSignals::DuplicateOpenFilter(int currentDirection)
{	
	if (currentDirection == OP_NONE || _lastOpenDirection == currentDirection) 
	{
		return OP_NONE;
	}
	
	if (currentDirection != _lastOpenDirection)
	{
		_lastOpenDirection = currentDirection;
		
		return _lastOpenDirection;
	}

	return OP_NONE;
}

int PSSignals::NearOpenFilter(int currentDirection, int nearBar = 1)
{	
	if (currentDirection == OP_NONE) 
	{
		return OP_NONE;
	}
	
	int currentBar = iBars(_symbol, _period);

	if (currentDirection == _nearOpenFilterDirection && (_nearOpenFilterBar + nearBar) >= currentBar ) 
	{
		return OP_NONE;
	}

	//if (currentDirection != _nearOpenFilterDirection)
	{
		_nearOpenFilterBar = currentBar;
		_nearOpenFilterDirection = currentDirection;
		
		return _nearOpenFilterDirection;
	}

	return OP_NONE;
}

int PSSignals::DuplicateOpenFilter(int highDirection, int currentDirection)
{	
	if (highDirection == OP_NONE || currentDirection == OP_NONE || highDirection != currentDirection)
	{
		return OP_NONE;
	}
	
	if (highDirection == currentDirection && highDirection != _lastOpenDirection)
	{
		_lastOpenDirection = highDirection;
		
		return _lastOpenDirection;
	}

	return OP_NONE;
}

int PSSignals::CheckAreSame(int highDirection, int currentDirection)
{	
	if (highDirection == OP_NONE || currentDirection == OP_NONE || highDirection != currentDirection)
	{
		return OP_NONE;
	}
	
	if (highDirection == currentDirection)
	{
		return highDirection;
	}

	return OP_NONE;
}

int PSSignals::DuplicateOpenFilter(int highDirection, int currentDirection, int lowDirection)
{	
	if (highDirection == OP_NONE || currentDirection == OP_NONE || lowDirection == OP_NONE ||
		highDirection != currentDirection || currentDirection != lowDirection || highDirection != lowDirection)
	{
		return OP_NONE;
	}
	
	if (highDirection == currentDirection && currentDirection == lowDirection && highDirection != _lastOpenDirection)
	{
		_lastOpenDirection = highDirection;
		
		return _lastOpenDirection;
	}

	return OP_NONE;
}

int PSSignals::CheckAreSame(int highDirection, int currentDirection, int lowDirection)
{	
	if (highDirection == OP_NONE || currentDirection == OP_NONE || lowDirection == OP_NONE ||
		highDirection != currentDirection || currentDirection != lowDirection || highDirection != lowDirection)
	{
		return OP_NONE;
	}
	
	if (highDirection == currentDirection && currentDirection == lowDirection)
	{
		return highDirection;
	}

	return OP_NONE;
}
