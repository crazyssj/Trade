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

#define MAX_OPEN_SIGNAL_ID 34
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
		
		int CheckCloseSignal(int currentDirection);

		int CheckForOpen(int highDirection, int currentDirection);
		int CheckForOpen(int highDirection, int currentDirection, int lowDirection);
		
		int OpenDuplicateFilter(int currentDirection);
		int OpenDuplicateFilter(int highDirection, int currentDirection);
		int OpenDuplicateFilter(int highDirection, int currentDirection, int lowDirection);
		
		int _OpenNearFilterBar;
		int _OpenNearFilterDirection;
		int OpenNearFilter(int currentDirection, int nearBar = 1);
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

	_OpenNearFilterBar = 0;
	_OpenNearFilterDirection = OP_NONE;
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
		//case 3: return OpenDuplicateFilter(_trendDetector.CurrentCspLine());
		// TODO: It must be refactoring. Signals are missmached.
		//case 4: return OpenDuplicateFilter(_trendDetector.CurrentCollaps());
		// TODO: It must be refactoring. Small signals.
		//case 5: return OpenDuplicateFilter(_trendDetector.CurrentEnvelop());
		// TODO: It must be refactoring. Signals are missmached.
		//case 6: return OpenDuplicateFilter(_trendDetector.CurrentWpr());
		// TODO: It must be refactoring.
		//case 8: return OpenDuplicateFilter(_trendDetector.CurrentMA2());
		case 1: return OpenDuplicateFilter(_trendDetector.CurrentShip());
		case 2: return OpenDuplicateFilter(_trendDetector.HighMA3(), _trendDetector.CurrentMA3());
		case 3: return OpenDuplicateFilter(_trendDetector.CurrentWpr2()); // old 7
		case 4: return _trendDetector.CurrentMacd(true); // old 9
		// TODO: ---------------- From here -------------------
		case 10: return OpenDuplicateFilter(_trendDetector.CurrentSidus(true));
		case 11: return OpenNearFilter(_trendDetector.CurrentSidusSafe(true), 3);
		// TODO: It must be refactoring. Signals are mismatched.
		//case 12: return _trendDetector.CurrentDifMA();
		case 13: return OpenDuplicateFilter(_trendDetector.CurrentZigZag());
		// TODO: It must be refactoring. Signals are too small.
		//case 14: return OpenDuplicateFilter(_trendDetector.CurrentInsideBar());
		// TODO: It must be refactoring. It doesn't send signals.
		//case 15: return _trendDetector.CurrentBUOVB_BEOVB();
		case 16: return _trendDetector.CurrentT1Signal1(true);
		// It react slower than _trendDetector.CurrentT1Signal1(true);
		//case 17: return _trendDetector.CurrentT1Signal2(true);
		// TODO: It must be refactoring. Signals are mismatched.
		//case 18: return _trendDetector.CurrentT2Signal1();
		case 19: return _trendDetector.CurrentT2Signal2();
		case 20: return OpenNearFilter(_trendDetector.CurrentT4Signal(true), 5);
		case 21: return OpenNearFilter(_trendDetector.ASCT_RAVI(), 3);
		case 22: return _trendDetector.CurrentHLHBTrendCatcher(false, false);
		case 23: return _trendDetector.CurrentHLHBTrendCatcher(true, false);
		case 24: return _trendDetector.CurrentHLHBTrendCatcher(false, true);
		case 25: return _trendDetector.CurrentHLHBTrendCatcher(true, true);
		case 26: return OpenNearFilter(_trendDetector.CurrentSTBollingerRev(), 5);
		// TODO: It must be refactoring. Signals are mismatched.
		//case 27: return _trendDetector.CurrentSMACrossoverPullback();
		case 28: return _trendDetector.CurrentExp11M();
		case 29: return CheckForOpen(_trendDetector.HighMA1(), _trendDetector.CurrentExp11M());
		//case 29: return CheckForOpen(_trendDetector.HighJ2JMA(), _trendDetector.CurrentExp11M());
		case 30: return CheckForOpen(_trendDetector.HighMAMANK(), _trendDetector.CurrentExp12M(), _trendDetector.LowMA_M15()); // 
		// TODO: It must be refactoring. Signals are mismatched.
		//case 31: return CheckForOpen(_trendDetector.HighStepMAStoch(), _trendDetector.CurrentExp14M(), _trendDetector.LowMA_M15());
		case 32: return CheckForOpen(_trendDetector.HighMA1(), _trendDetector.CurrentThreeTF1(), _trendDetector.LowMA_M15());
		case 33: return OpenNearFilter(_trendDetector.The3Ducks(), 5);

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
		case 1: return _trendDetector.HighMA1();
		case 2: return _trendDetector.HighMA3();
		case 3: return _trendDetector.HighMAMANK();
		case 4: return _trendDetector.HighStepMAStoch();
		case 5: return _trendDetector.HighJ2JMA();
		case 6: return _trendDetector.CurrentMacd(false);
		case 7: return _trendDetector.CurrentSidus(false);
		case 8: return _trendDetector.CurrentSidusSafe(false);
		case 9: return _trendDetector.CurrentT1Signal1(false);
		case 10: return _trendDetector.CurrentT1Signal2(false);
		case 11: return _trendDetector.CurrentT4Signal(false);
		case 12: return _trendDetector.CurrentExp11M();
		case 13: return _trendDetector.CurrentExp12M();
		case MAX_CLOSE_SIGNAL_ID: return _trendDetector.Exp11(false);

		default: 
			return OP_NONE;
	}

	return OP_NONE;
}

int PSSignals::CheckCloseSignal(int currentDirection)
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

int PSSignals::OpenDuplicateFilter(int currentDirection)
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

int PSSignals::OpenNearFilter(int currentDirection, int nearBar = 1)
{	
	if (currentDirection == OP_NONE) 
	{
		return OP_NONE;
	}
	
	int currentBar = iBars(_symbol, _period);

	if (currentDirection == _OpenNearFilterDirection && (_OpenNearFilterBar + nearBar) >= currentBar ) 
	{
		return OP_NONE;
	}

	//if (currentDirection != _OpenNearFilterDirection)
	{
		_OpenNearFilterBar = currentBar;
		_OpenNearFilterDirection = currentDirection;
		
		return _OpenNearFilterDirection;
	}

	return OP_NONE;
}

int PSSignals::OpenDuplicateFilter(int highDirection, int currentDirection)
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

int PSSignals::CheckForOpen(int highDirection, int currentDirection)
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

int PSSignals::OpenDuplicateFilter(int highDirection, int currentDirection, int lowDirection)
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

int PSSignals::CheckForOpen(int highDirection, int currentDirection, int lowDirection)
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
