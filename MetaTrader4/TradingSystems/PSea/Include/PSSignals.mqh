//+------------------------------------------------------------------+
//|                                                    PSSignals.mqh |
//|                                   Copyright 2019, PSInvest Corp. |
//|                                          https://www.psinvest.eu |
//+------------------------------------------------------------------+
// Signals functions
#property copyright "Copyright 2019, PSInvest Corp."
#property link      "https://www.psinvest.eu"
#property version   "4.00"
#property strict
#include <FileLog.mqh>
#include <PSMarket.mqh>
#include <PSTrendDetector.mqh>

#define MAX_SIGNAL_ID 8

class PSSignals
{
	public:
		PSSignals(CFileLog *fileLog, string symbol, int period, int signalId);
		~PSSignals();
		bool IsInitialised();
		int Open();
		int Close(int orderType, int closeSignal, double closeCoefficient);
		int GetMagicNumber();
		bool IsMagicNumberBelong(int magicNumber);
	private:
		CFileLog *_fileLog;
		PSTrendDetector *_trendDetector;
		PSMarket *_market;
		
		string _symbol;
		int _period;

		bool _isInitialised;
		void CheckInputValues();

		int _signalId;

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

		int DetectClose(int orderType, int currentDirection);

		// -- Systems --
		int T1Signal();
		int T2Signal();
		int MyIdea1();
		int HLHBTrendCatcher1();
		int HLHBTrendCatcher2();
		int HLHBTrendCatcher4();
		int Exp11();
		int Exp12();
};

PSSignals::PSSignals(CFileLog *fileLog, string symbol, int period, int signalId)
{
	_trendDetector = new PSTrendDetector(fileLog, symbol, period);
	_market = new PSMarket(fileLog, symbol, period);

	_fileLog = fileLog;
	_symbol = symbol;
	_period = period;
	_signalId = signalId;

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
	delete _market;
}

void PSSignals::CheckInputValues()
{
	bool log = _fileLog != NULL;
	if (!log) {
		//_fileLog.Error(StringConcatenate(__FUNCTION__, " FileLog must not be NULL!"));
		Print(StringConcatenate(__FUNCTION__, " FileLog must not be NULL!"));
		_isInitialised = false;
		return;
	}
	
	bool trendDetector = _trendDetector.IsInitialised();
	if (!trendDetector) {
		_fileLog.Error(StringConcatenate(__FUNCTION__, " TrendDetector is not initialised!"));
	}

	bool symbol = _market.IsSymbolValid(_symbol);
	if (!symbol) {
		_fileLog.Error(StringConcatenate(__FUNCTION__, " Symbol: ", _symbol, " is not valid by system!"));
	}

	bool period = _market.IsTimeFrameValid(_period);
	if (!period) {
		_fileLog.Error(StringConcatenate(__FUNCTION__, " Time frame: ", _period, " is not valid by system!"));
	}

	bool signal = _signalId > 0 && _signalId <= MAX_SIGNAL_ID;
	if (!signal) {
		_fileLog.Error(StringConcatenate(__FUNCTION__, " SignalId: ", _signalId, " must be from: 1 to ", MAX_SIGNAL_ID));
	}

	_isInitialised = log && trendDetector && symbol && period && signal;

	if (!_isInitialised) 
	{
		_fileLog.Error(StringConcatenate(__FUNCTION__, " PSSignals is not initialised!"));
	}
	else
	{
		_fileLog.Info(StringConcatenate(__FUNCTION__, " PSSignals is initialised. Symbol: ", _symbol, ", Period (in minute): ", _period, 
			", Signal Id: ", _signalId));
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

	int symbolId = _market.GetSymbolIndex(_symbol);
	int periodId = _market.GetTimeFrameIndex(_period);

	_magicNumber = 
		symbolId * 100000000 +
		periodId * 10000000 +
		_signalId * 100000; //+
		//_signalCloseId * 1000;
	
	_maxMagicNumber = _magicNumber + 99999;
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

	int result = OP_NONE;

	switch (_signalId)
	{
		case 1: result = MyIdea1(); break; // old 20
		case 2: result = T1Signal(); break; // old 8
		case 3: result = T2Signal(); break; // old 9
		case 4: result = HLHBTrendCatcher1(); break; // old 12
		case 5: result = HLHBTrendCatcher2(); break; // old 13
		case 6: result = HLHBTrendCatcher4(); break; // old 15
		case 7: result = Exp12(); break; // old 19

		case MAX_SIGNAL_ID: 
				result = Exp11(); break; // old 22
		
		default: 
			result = OP_NONE;  break;
	}

	if (result != OP_NONE)
	{
		_trendDetector.ResetCloseValues(result);
	}
	
	return result;
}

int PSSignals::Exp11()
{
	return _trendDetector.Exp11(true);
}

int PSSignals::Exp12()
{
	return CheckAreSame(_trendDetector.High1MAMANK(), _trendDetector.CurrentJtatl4(), _trendDetector.Low1MA8_M15());
}

int PSSignals::HLHBTrendCatcher4()
{
	return _trendDetector.CurrentHLHBTrendCatcher(true, true);
}

int PSSignals::HLHBTrendCatcher2()
{
	return _trendDetector.CurrentHLHBTrendCatcher(true, false);
}

int PSSignals::HLHBTrendCatcher1()
{
	return _trendDetector.CurrentHLHBTrendCatcher(false, false);
}

int PSSignals::T2Signal()
{
	return _trendDetector.CurrentT2Signal2();
}

int PSSignals::T1Signal()
{
	return _trendDetector.CurrentT1Signal(true, 10, 100);
}

int PSSignals::MyIdea1()
{
	return CheckAreSame(_trendDetector.High2MA3(), _trendDetector.Current1OsMA6_45_5(), _trendDetector.Low1MA8_M15());
}

// @brief Process close signals
// @return OP_NONE - no action necessary, OP_BUY - close Buy orders, OP_SELL - close sell orders.
int PSSignals::Close(int orderType, int closeSignalId, double closeCoefficient)
{
	if (orderType == OP_NONE || !IsNewBar(false)) {
		return OP_NONE;
	}

	int result = OP_NONE;
	
	switch (closeSignalId)
	{
		case 1: result = _trendDetector.CurrentCloseMaAtrFlt(orderType, closeCoefficient); break;
		case 2: result = _trendDetector.CurrentCloseMA7EC(orderType); break;

		case 3: 
				result = result = _trendDetector.CurrentCloseJfatl(orderType); break; // old 22

		default: 
			return result = OP_NONE;
	}
	

	// switch (_signalId)
	// {
	// 	case 1: result = _trendDetector.CurrentCloseMA7EC(orderType); break;
	// 	case 2: result = _trendDetector.CurrentCloseMA7EC(orderType); break;
	// 	case 3: result = _trendDetector.CurrentCloseMA7EC(orderType); break;
	// 	case 4: result = _trendDetector.CurrentCloseMA7EC(orderType); break;
	// 	case 5: result = _trendDetector.CurrentCloseMA7EC(orderType); break;
	// 	case 6: result = _trendDetector.CurrentCloseJfatl(orderType); break;
	// 	case 7: result = _trendDetector.CurrentCloseMA7EC(orderType); break;

	// 	case MAX_SIGNAL_ID: 
	// 			result = _trendDetector.CurrentCloseMA7EC(orderType); break; // old 22

	// 	default: 
	// 		return result = OP_NONE;
	// }

	return result;
}

int PSSignals::DetectClose(int orderType, int currentDirection)
{
	if (orderType == OP_NONE || currentDirection == OP_NONE || 
		orderType == currentDirection) 
	{
		return OP_NONE;
	}
	
	return orderType;
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
