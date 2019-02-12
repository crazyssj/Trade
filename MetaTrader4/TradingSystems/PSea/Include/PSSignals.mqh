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

		int _signalOpenId;
		int _signalCloseId;

		int _lastBarNum;
		bool IsNewBar();

		int _lastCloseDirection;
		int _lastOpenDirection;

		int _magicNumber;
		int _maxMagicNumber;
		void BuildMagicNumber();
		
		int CheckCloseSignal(int currentDirection);

		int CheckOpenSignal(int currentDirection);
		int CheckOpenSignal(int highDirection, int currentDirection);
		int CheckOpenSignal(int highDirection, int currentDirection, int lowDirection);
};

PSSignals::PSSignals(CFileLog *fileLog, string symbol, int period, int signalOpenId, int signalCloseId)
{
	_trendDetector = new PSTrendDetector(fileLog, symbol, period);

	_fileLog = fileLog;
	_symbol = symbol;
	_period = period;
	_signalOpenId = signalOpenId;
	_signalCloseId = signalCloseId;

	// TODO Add validation symbol, period, signalOpenId and signalCloseId
	_isInitialised = _fileLog != NULL && _trendDetector.IsInitialised() && IsSymbolValid(_symbol) && IsTimeFrameValid(_period) 
		&& _signalOpenId > 0 && _signalCloseId > 0 /* && _signalOpenId <= ...  */ /* && _signalCloseId <= ...*/;

	if (!_isInitialised) 
	{
		_fileLog.Error(StringConcatenate(__FUNCTION__, " PSSignals is not initialised!"));
	}
	else
	{
		_fileLog.Info(StringConcatenate(__FUNCTION__, " PSSignals is initialised. Symbol: ", _symbol, ", Period (in minute): ", period, 
			", Open signal Id: ", _signalOpenId, ", Signal close Id: ", _signalCloseId));
		
		BuildMagicNumber();
	}
	
	_lastBarNum = 0;
	
	_lastOpenDirection = OP_NONE;
	_lastCloseDirection = OP_NONE;
}

PSSignals::~PSSignals()
{
	delete _trendDetector;
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

bool PSSignals::IsNewBar()
{
	int currentBarNumber = iBars(_symbol, _period);

   // Process logics only if new bar is appaired.
   if(currentBarNumber == _lastBarNum)
   {
      return false;
   }

   _lastBarNum = currentBarNumber;

   return true;
}

// @brief Process open signals
// @return OP_NONE - isn't necessary any action, OP_BUY - open Buy orders, OP_SELL - open sell orders.
int PSSignals::Open()
{
	if (!IsNewBar()) {
		return OP_NONE;
	}

	switch (_signalOpenId)
	{
		case 1: return CheckOpenSignal(_trendDetector.CurrentShip());
		case 2: return CheckOpenSignal(_trendDetector.HighMA3(), _trendDetector.CurrentMA3());
		case 3: return CheckOpenSignal(_trendDetector.CurrentCspLine());
		case 4: return CheckOpenSignal(_trendDetector.CurrentCollaps());
		case 5: return CheckOpenSignal(_trendDetector.CurrentEnvelop());
		case 6: return CheckOpenSignal(_trendDetector.CurrentWpr());
		case 7: return CheckOpenSignal(_trendDetector.CurrentWpr2());
		case 8: return CheckOpenSignal(_trendDetector.CurrentMA2());
		case 9: return CheckOpenSignal(_trendDetector.CurrentMacd(true));
		case 10: return CheckOpenSignal(_trendDetector.CurrentSidus(true));
		case 11: return CheckOpenSignal(_trendDetector.CurrentSidusSafe(true));
		case 12: return CheckOpenSignal(_trendDetector.CurrentDifMA());
		case 13: return CheckOpenSignal(_trendDetector.CurrentZigZag());
		case 14: return CheckOpenSignal(_trendDetector.CurrentInsideBar());
		case 15: return CheckOpenSignal(_trendDetector.CurrentBUOVB_BEOVB());
		case 16: return CheckOpenSignal(_trendDetector.CurrentT1Signal1(true));
		case 17: return CheckOpenSignal(_trendDetector.CurrentT1Signal2(true));
		case 18: return CheckOpenSignal(_trendDetector.CurrentT2Signal1());
		case 19: return CheckOpenSignal(_trendDetector.CurrentT2Signal2());
		case 20: return CheckOpenSignal(_trendDetector.CurrentT4Signal(true));
		case 21: return CheckOpenSignal(_trendDetector.CurrentASCT_RAVI());
		case 22: return CheckOpenSignal(_trendDetector.CurrentHLHBTrendCatcher(false, false));
		case 23: return CheckOpenSignal(_trendDetector.CurrentHLHBTrendCatcher(true, false));
		case 24: return CheckOpenSignal(_trendDetector.CurrentHLHBTrendCatcher(false, true));
		case 25: return CheckOpenSignal(_trendDetector.CurrentHLHBTrendCatcher(true, true));
		case 26: return CheckOpenSignal(_trendDetector.CurrentSTBollingerRev());
		case 27: return CheckOpenSignal(_trendDetector.CurrentSMACrossoverPullback());
		case 29: return CheckOpenSignal(_trendDetector.HighMA1(), _trendDetector.CurrentExp11M());
		case 30: return CheckOpenSignal(_trendDetector.HighMAMANK(), _trendDetector.CurrentExp12M(), _trendDetector.LowJFatlM5());
		case 31: return CheckOpenSignal(_trendDetector.HighStepMAStoch(), _trendDetector.CurrentExp14M(), _trendDetector.LowMA_M15());
		case 32: return CheckOpenSignal(_trendDetector.HighMA1(), _trendDetector.CurrentThreeTF1(), _trendDetector.LowMA_M15());
		case 33: return CheckOpenSignal(_trendDetector.The3Ducks());
		case 34: return CheckOpenSignal(_trendDetector.Exp11(true));
		default: return OP_NONE;
	}

	return OP_NONE;
}

// @brief Process close signals
// @return OP_NONE - no action necessary, OP_BUY - close Buy orders, OP_SELL - close sell orders.
int PSSignals::Close()
{
	if (!IsNewBar()) {
		return OP_NONE;
	}

	switch (_signalCloseId)
	{
		case 1: return CheckCloseSignal(_trendDetector.HighMA1());
		case 2: return CheckCloseSignal(_trendDetector.HighMAMANK());
		case 3: return CheckCloseSignal(_trendDetector.HighStepMAStoch());
		case 4: return CheckCloseSignal(_trendDetector.HighMA3());
		case 5: return _trendDetector.CurrentMacd(false);
		case 6: return _trendDetector.CurrentSidus(false);
		case 7: return _trendDetector.CurrentSidusSafe(false);
		case 8: return _trendDetector.CurrentT1Signal1(false);
		case 9: return _trendDetector.CurrentT1Signal2(false);
		case 10: return _trendDetector.CurrentT4Signal(false);
		case 11: return _trendDetector.Exp11(false);
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

int PSSignals::CheckOpenSignal(int currentDirection)
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

int PSSignals::CheckOpenSignal(int highDirection, int currentDirection)
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

int PSSignals::CheckOpenSignal(int highDirection, int currentDirection, int lowDirection)
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