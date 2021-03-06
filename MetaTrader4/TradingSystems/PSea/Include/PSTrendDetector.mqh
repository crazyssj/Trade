//+------------------------------------------------------------------+
//|                                              PSTrendDetector.mqh |
//|                                   Copyright 2019, PSInvest Corp. |
//|                                          https://www.psinvest.eu |
//+------------------------------------------------------------------+
// Old PSSignals 2.0
// Necessary add indicator laguerre.mq4, MAMA_NK.mq4, JFatl.mq4, JCCIX.mq4, StepMA_Stoch_NK.mq4
#property copyright "Copyright 2019, PSInvest Corp."
#property link      "https://www.psinvest.eu"
#property version   "1.00"
#property strict
#include <FileLog.mqh>
#include <PSMarket.mqh>

const string IndicatorNameLaguerre = "laguerre";
const string IndicatorNameJFatl = "JFatl";
const string IndicatorNameMAMA_NK = "MAMA_NK";
const string IndicatorNameJCCIX = "JCCIX";
const string IndicatorNameStepMAStoch = "StepMA_Stoch_NK";
const string IndicatorNameJ2JMA = "J2JMA";

struct LastBarData
{
	int LastBarNumber;
	// OP_NONE no direction, OP_BUY, OP_SELL
	int CurrentTrend;
	// OP_NONE no direction, OP_BUY, OP_SELL
	//int LastTrend;
};

class PSTrendDetector
{
	public:
		PSTrendDetector(CFileLog *fileLog, string symbol, int period);
		~PSTrendDetector();
		bool IsInitialised();

		// -- High -- 
		// Big trend detection. It is necessary for close/open operation.
		int High2MA3();
		int High4MA4_8();
		int High1MAMANK();
		int High1StepMAStoch();
		int High1J2JMA();

		// -- Low --
		// Them we use for noise detection. 
		int Low1JFatl_M5();
		int Low1MA8_M15();

		// -- Current --
		// Use them for enter in position
		int CurrentShip();
		int Current5MA();
		int CurrentCspLine();
		int CurrentCollaps();
		int CurrentEnvelop();
		int CurrentCalc1Wpr();
		int CurrentWpr();
		int Current3MA2SAR();
		int CurrentDifMA();
		int CurrentZigZag();
		int CurrentInsideBar();
		int CurrentBUOVB_BEOVB();
		int CurrentT2Signal1();
		int CurrentT2Signal2();
		int CurrentHLHBTrendCatcher(bool checkADX, bool checkMACD);
		int CurrentSTBollingerRev();
		int CurrentSMACrossoverPullback();
		int CurrentExp11M();
		int CurrentJtatl4();
		int CurrentExp14M();
		int Current1OsMA6_45_5();
		int CurrentT4Signal();

		// -- Current mixed for Open and Close
		int CurrentMacd(bool isEntry);
		int CurrentSidus(bool isEntry);
		int CurrentSidusSafe(bool isEntry);
		int CurrentT1Signal(bool isEntry, int fastMAPeriod, int slowMAPeriod);

		int Low1MA7LM();

		// Un separated systems.
		// TODO Separate these system.
		int The3Ducks();
		int Exp11(bool isEntry);
		int ASCT_RAVI();

		// Close signals
		int CurrentCloseMA7EC(int orderType);
		int CurrentCloseMaAtrFlt(int orderType, double closeCoefficient);
		int CurrentCloseJfatl(int orderType);
		void ResetCloseValues(int orderType);
		double GetAtrStopLoss();

	private:
		CFileLog *_fileLog;
		PSMarket *_market;
		string _symbol;
		int _period;
		int _periodPlus1;
		int _periodMinus1;
		int _periodMinus2;
		int _digits;
		int _tfLastBarNum;
		bool _isValid;
		int _smaCrossoverPullbackCross;
		double _currentCloseBuy;
		double _currentCloseSell;

		LastBarData _highMA1Data;
		LastBarData _highMAMANKData;
		LastBarData _highStepMAStochData;
		LastBarData _highMA3Data;
		LastBarData _highJ2JMA;
		LastBarData _lowJFatlM5Data;
		LastBarData _lowMA_M15Data;
		LastBarData _lowMA_M30Data;

		void InitLastBarData(LastBarData &data);
		int DetectTrend(double d1, double d2);
		int DetectTrend(double d11, double d12, double d21, double d22);
		//bool IsTrendChanged(double d1, double d2, LastBarData &data);

		double RAVI_Up[4];
		double RAVI_Dn[4];
		double RAVI_Buffer[4][5];
		double ASCTrend1_Up[4];
		double ASCTrend1_Dn[4];
		double ASCTrend1_Buffer[2][2];
		bool Get_ASCTrend1(int Number, string symbol,int timeframe, 
                   bool NullBarRecount, int RISK);
		bool Get_RAVI(int Number, string symbol,int timeframe, 
					bool NullBarRecount, int Period1, int Period2, 
					int MA_Metod,  int  PRICE);

		int CurrentT2Signal(int periodCCI, int levelCCI);
};

PSTrendDetector::PSTrendDetector(CFileLog *fileLog, string symbol, int period)
{
	_market = new PSMarket(fileLog, symbol, period);
	
	_fileLog = fileLog;
	_symbol = symbol;
	_period = period;
	_digits = Digits;
	
	_isValid = true;

	if (_period > PERIOD_W1) {
		_fileLog.Error(StringConcatenate(__FUNCTION__, " Period shouldn't greater than PERIOD_W1. Current:", period));
		_isValid = false;
	}

	if (_period < PERIOD_M15) {
		_fileLog.Error(StringConcatenate(__FUNCTION__, " Period shouldn't lower than PERIOD_M15. Current:", period));
		_isValid = false;
	}

	_tfLastBarNum = 0;
	_periodPlus1 = _market.GetNextTimeFrame(_period, 1);
	_periodMinus1 = _market.GetPreviousTimeFrame(_period, 1);
	_periodMinus2 = _market.GetPreviousTimeFrame(_period, 2);

	_smaCrossoverPullbackCross = 0;

	InitLastBarData(_highMA1Data);
	InitLastBarData(_highMAMANKData);
	InitLastBarData(_highStepMAStochData);
	InitLastBarData(_highMA3Data);
	InitLastBarData(_highJ2JMA);

	InitLastBarData(_lowJFatlM5Data);
	InitLastBarData(_lowMA_M15Data);
	InitLastBarData(_lowMA_M30Data);

	_currentCloseBuy = 0;
	_currentCloseSell = 0;
}

PSTrendDetector::~PSTrendDetector()
{
	delete _market;
}

bool PSTrendDetector::IsInitialised()
{
	return _isValid;
}

void PSTrendDetector::InitLastBarData(LastBarData &data)
{
	data.LastBarNumber = 0;
	data.CurrentTrend = OP_NONE;
	//data.LastTrend = OP_NONE;
}

int PSTrendDetector::DetectTrend(double d1, double d2)
{
	double d = d1 - d2;
	if (d > 0) {
		return OP_BUY;
	}
	
	if (d < 0) {
		return OP_SELL;
	}
	
	return OP_NONE;
}

int PSTrendDetector::DetectTrend(double d11, double d12, double d21, double d22)
{
	double d1 = d11 - d12;
	double d2 = d21 - d22;
	if (d1 == 0 && d2 == 0) {
		return OP_NONE;
	}
	
	if (d1 > 0 && d2 > 0) {
		return OP_BUY;
	}

	if (d1 < 0 && d2 < 0) {
		return OP_SELL;
	}
	
	return OP_NONE;
}

// bool IsTrendChanged(double d1, double d2, LastBarData &data)
// {
// 	int trend = DetectTrend(d1, d2);

// 	if (data.TrentDirection != trend) {
// 		data.TrentDirection == trend;

// 		return true;
// 	}
	
// 	return false;
// }

// @brief old Collaps
// @stars **
// @info It is for good trend
// @old V1 3 signal
// TODO Refactoring
int PSTrendDetector::CurrentCollaps()
{
	const int maPeriod = 120;

	double laguerre = iCustom(_symbol, _period, IndicatorNameLaguerre, 0.7, 100, 0, 1);
	double cci = iCCI(_symbol, _period, 14, PRICE_CLOSE, 0);
	double MA0 = iMA(_symbol, _period, maPeriod, 0, MODE_EMA, PRICE_MEDIAN, 0);
	double MA1 = iMA(_symbol, _period, maPeriod, 0, MODE_EMA, PRICE_MEDIAN, 1);

	int trend = DetectTrend(MA0, MA1);
	
	if (laguerre == 0 && trend == OP_BUY && cci < -10) 
		return OP_BUY;

	if (laguerre == 1 && trend == OP_SELL && cci > 10) 
		return OP_SELL;

	return OP_NONE;
}

// @brief Old CspLine
// @stars ***
// @info It is for orders without SL and Hedge orders.
// @old V1 4 signal
// TODO Refactoring
int PSTrendDetector::CurrentCspLine()
{
	// static bool isBought = false;
	// static bool isSold = false;

	int i;
	//datetime time;
	double dp=0.0, mid=0.0, atr=0.0;
	double buy, sell;

	i = 1;//iBarShift(_symbol, _period, time);
	atr = iATR(_symbol, _period, 15, i);
	dp = MathAbs(Open[i] - Close[i]);
	
	mid = (Open[i] + Close[i]) / 2;
	
	if (dp > 50)	
	{ 
		buy = Close[i]+atr; 
		sell = Close[i]-atr;
	}
	else 
	{ 
		buy = mid+atr; 
		sell= mid-atr; 
	}

	if (Ask > buy /*&& !isBought*/) 
	{
		//isBought = true; 
		return OP_BUY;
	}
	
	if (Bid < sell /*&& !isSold*/) 
	{
		//isSold = true; 
		return OP_SELL;
	}

   return OP_NONE;
}

// @brief Old DifMA
// @stars **
// @info It is for counter trend + Hedge
// @old V1 5 signal
// TODO Refactoring
int PSTrendDetector::CurrentDifMA()
{
	const int MA5 = 5;
	const int MA7 = 7;
	const int MA25 = 25;
	const int MA27 = 27;
	const int MA55 = 55;
	const int MA57 = 57;
	const int MODE_MA = MODE_EMA;
	const int PRICE = PRICE_MEDIAN;

	double x = iMA(_symbol, _period, MA5, 0, MODE_MA, PRICE, 0);	
	double x0 = iMA(_symbol, _period, MA5, 0, MODE_MA, PRICE, 1); 
	double dx1 = x-x0; 
	double xx1 = x0;
	
	x = iMA(_symbol, _period, MA7, 0, MODE_MA, PRICE, 0);	
	x0 = iMA(_symbol, _period, MA7, 0, MODE_MA, PRICE, 1); 
	double dx2 = x-x0; 
	double xx2 = x0;
	double dxCurA = 100*(dx1-dx2);

	double x1 = iMA(_symbol, _period, MA5, 0, MODE_MA, PRICE, 2); 
	dx1 = xx1-x1;
	
	x1 = iMA(_symbol, _period, MA7, 0, MODE_MA, PRICE, 2); 
	dx2 = xx2-x1;
	double dxPreA = 100*(dx1-dx2);

	x = iMA(_symbol, _period, MA25, 0, MODE_MA, PRICE, 0);	
	x0 = iMA(_symbol, _period, MA25, 0, MODE_MA, PRICE, 1); 
	dx1 = x-x0; 
	xx1 = x0;
	
	x = iMA(_symbol, _period, MA27, 0, MODE_MA, PRICE, 0);	
	x0 = iMA(_symbol, _period, MA27, 0, MODE_MA, PRICE, 1); 
	dx2 = x-x0; 
	xx2 = x0;
	double dxCurB = 100*(dx1-dx2);
	
	x1 = iMA(_symbol, _period, MA25, 0, MODE_MA, PRICE, 2); 
	dx1 = xx1-x1;
	x1 = iMA(_symbol, _period, MA27, 0, MODE_MA, PRICE, 2); 
	dx2 = xx2-x1;
	double dxPreB = 100*(dx1-dx2);

	x = iMA(_symbol, _period, MA55, 0, MODE_MA, PRICE, 0);	
	x0 = iMA(_symbol, _period, MA55, 0, MODE_MA, PRICE, 1); 
	dx1 = x-x0; 
	xx1 = x0;
	
	x = iMA(_symbol, _period, MA57, 0, MODE_MA, PRICE, 0);	
	x0 = iMA(_symbol, _period, MA57, 0, MODE_MA, PRICE, 1); 
	dx2 = x-x0; 
	xx2 = x0;
	double dxCurC = 100*(dx1-dx2);
	
	x1 = iMA(_symbol, _period, MA55, 0, MODE_MA, PRICE, 2); 
	dx1 = xx1-x1;
	x1 = iMA(_symbol, _period, MA57, 0, MODE_MA, PRICE, 2); 
	dx2 = xx2-x1;
	double dxPreC = 100*(dx1-dx2);

	if( ((dxCurA > dxPreA) && (dxCurB > dxPreB) && (dxCurC > dxPreC)) &&	((dxCurB > 0 && dxPreB < 0) && (dxCurC > 0 && dxPreC < 0)) )
		return (OP_BUY);
	
	if( ((dxCurA < dxPreA) && (dxCurB < dxPreB) && (dxCurC < dxPreC)) && ((dxCurB < 0 && dxPreB > 0) && (dxCurC < 0 && dxPreC > 0)) )
		return (OP_SELL);
 
   return OP_NONE;
}

// @brief Old Envelop
// @stars ***
// @info It is can work for additional counter trend + Hedge
// @old V1 7 signal
// TODO Refactoring
int PSTrendDetector::CurrentEnvelop()
{
	const int slowMAPeriod = 21;
	const double Deviation = 0.6;
	const int Mode = MODE_SMA;//0-sma, 1-ema, 2-smma, 3-lwma
	const int Price = PRICE_CLOSE;//0-close, 1-open, 2-high, 3-low, 4-median, 5-typic, 6-wieight
	
	double envH0, envL0, m0;
	double envH1, envL1, m1;
	envH0 = iEnvelopes(_symbol, _period, slowMAPeriod, Mode, 0, Price, Deviation, MODE_UPPER, 0); 
	envH1 = iEnvelopes(_symbol, _period, slowMAPeriod, Mode, 0, Price, Deviation, MODE_UPPER, 1); 

	envL0 = iEnvelopes(_symbol, _period, slowMAPeriod, Mode, 0, Price, Deviation, MODE_LOWER, 0); 
	envL1 = iEnvelopes(_symbol, _period, slowMAPeriod, Mode, 0, Price, Deviation, MODE_LOWER, 1); 

	m0 = (Low[0] + High[0]) / 2;	
	m1 = (Low[1] + High[1]) / 2;
	
	if (envL0 > m0 && envL1 > m1) 
		return OP_SELL;

	if (envH0 < m0 && envH1 < m1) 
		return OP_BUY;

   return OP_NONE;
}

// @brief Old Ship
// @stars ***
// @info It works only in strong trend.
// @old V1 9 signal
// TODO Refactoring
int PSTrendDetector::CurrentShip()
{
	double ao0, ac0, ao1, ac1, sar, adxp, adxn, al1, al2, al3;
	
	adxp = iADX(_symbol, _period, 14, PRICE_CLOSE, MODE_PLUSDI, 0);
	adxn = iADX(_symbol, _period, 14, PRICE_CLOSE, MODE_MINUSDI, 0);
	
	ao0=iAO(_symbol, _period, 0); 
	ao1=iAO(_symbol, _period, 1);
	
	ac0=iAC(_symbol, _period, 0); 
	ac1=iAC(_symbol, _period, 1);
	
	sar = iSAR(_symbol, _period, 0.02, 0.2, 0);
	
	al1 = iAlligator(_symbol, _period, 13, 8, 8, 5, 5, 3, MODE_SMMA, PRICE_MEDIAN, MODE_GATORLIPS, 0);
	al2 = iAlligator(_symbol, _period, 13, 8, 8, 5, 5, 3, MODE_SMMA, PRICE_MEDIAN, MODE_GATORTEETH, 0);
	al3 = iAlligator(_symbol, _period, 13, 8, 8, 5, 5, 3, MODE_SMMA, PRICE_MEDIAN, MODE_GATORJAW, 0);
	
	if (ao0>ao1 && ac0>ac1 && Open[0]>=al1 && al1>al2 && al2>al3 && Low[0]>=sar && adxp>adxn) 
		return (OP_BUY);

	if (ao0<ao1 && ac0<ac1 && Open[0]<=al1 && al1<al2 && al2<al3 && High[0]<=sar && adxp<adxn) 
		return (OP_SELL);

	return OP_NONE;
}

// @brief Old Macd
// @stars ****
// @info It works only in strong trend. It has good logics but sends and fake signals.
// @old V1 12 signal
// TODO Refactoring
int PSTrendDetector::CurrentMacd(bool isEntry)
{
	const int MODE_MA = MODE_EMA;
	const int PRICE_MA = PRICE_CLOSE;
	const double MACDOpen = 3 * Point;

	int maPeriod=26;

	double MacdCur = iMACD(_symbol, _period, 8,17,9,PRICE_MA,MODE_MAIN,0);
	double MacdPre = iMACD(_symbol, _period, 8,17,9,PRICE_MA,MODE_MAIN,1);

	double SignalCur = iMACD(_symbol, _period, 8,17,9,PRICE_MA,MODE_SIGNAL,0);
	double SignalPre = iMACD(_symbol, _period, 8,17,9,PRICE_MA,MODE_SIGNAL,1);

	double MaCur = iMA(_symbol, _period, maPeriod,0,MODE_MA,PRICE_MA,0);
	double MaPre = iMA(_symbol, _period, maPeriod,0,MODE_MA,PRICE_MA,1);

	if (isEntry) 
	{
		if(MacdCur < 0 && MacdCur > SignalCur && MacdPre < SignalPre && MathAbs(MacdCur) > MACDOpen && MaCur > MaPre) 
			return OP_BUY;
		
		if(MacdCur > 0 && MacdCur < SignalCur && MacdPre > SignalPre && MacdCur > MACDOpen && MaCur < MaPre) 
			return OP_SELL;
	}
	else
	{	
		const double MACDClose = 2 * Point;
      	if( (MacdCur > 0 && MacdCur < SignalCur && MacdPre > SignalPre && MacdCur > MACDClose) ||
		    (MacdCur > 0 && MacdCur < SignalCur && MacdPre > SignalPre && MacdCur > MACDOpen && MaCur < MaPre))
		   		return OP_BUY;

      	if( (MacdCur < 0 && MacdCur > SignalCur && MacdPre < SignalPre && MathAbs(MacdCur) > MACDClose) ||
		    (MacdCur < 0 && MacdCur > SignalCur && MacdPre < SignalPre && MathAbs(MacdCur) > MACDOpen && MaCur > MaPre))
				return OP_SELL;
	}
 
   return OP_NONE;
}

// @brief Old MA2
// @stars ***
// @info It would work with bigger SL and low profit.
// @old V1 15 signal
// TODO Refactoring
int PSTrendDetector::Current3MA2SAR()
{
	const int PRICE = PRICE_CLOSE;
	const int slowMAPeriod = 300;
	const int fastMAPeriod = 30;	 

	double sMa1 = iMA(_symbol, _period, slowMAPeriod,0,MODE_SMA,PRICE,3);	
	double sMa0 = iMA(_symbol, _period, slowMAPeriod,0,MODE_SMA,PRICE,0);
	double fMa1 = iMA(_symbol, _period, fastMAPeriod,0,MODE_EMA,PRICE,3) * 0.998;	
	double fMa0 = iMA(_symbol, _period, fastMAPeriod,0,MODE_EMA,PRICE,0) * 0.998;
	double sar1 = iSAR(_symbol, _period, 0.02, 0.2, 6);	
	double sar0 = iSAR(_symbol, _period, 0.02, 0.2, 0);

   	if ((sMa1 > fMa1 && sMa0 < fMa0) && sar1 > Open[6] && sar0 < Open[0]) 
		return (OP_BUY);
   	
	if ((sMa1 < fMa1 && sMa0 > fMa0) && sar1 < Open[6] && sar0 > Open[0]) 
		return (OP_SELL);
   
	return OP_NONE;
}

// @brief Old MA3
// @stars ****
// @info It looks good, necessary more tests.
// @old V1 16 signal
// TODO Refactoring
int PSTrendDetector::Current5MA()
{
	const int d5=5, d20=20;
	double d5_0, d5_1, d5_2, d20_0, d20_1;
	
	// 	d5_0 = iMA(NULL, PERIOD_D1, d5, 0, MODE_SMA, PRICE_CLOSE, 0);
	d5_0 = iMA(_symbol, _period, d5, 0, MODE_SMA, PRICE_CLOSE, 0);
	d5_1 = iMA(_symbol, _period, d5, 0, MODE_SMA, PRICE_CLOSE, 1);
	d5_2 = iMA(_symbol, _period, d5, 0, MODE_SMA, PRICE_CLOSE, 2);
	d20_0 = iMA(_symbol, _period, d20, 0, MODE_SMA, PRICE_CLOSE, 0);
	d20_1 = iMA(_symbol, _period, d20, 0, MODE_SMA, PRICE_CLOSE, 1);
	
	if (d20_0 > d20_1 && d5_0 > d5_1 && d5_2 > d5_1) 
		return (OP_BUY);
	
	if (d20_0 < d20_1 && d5_0 < d5_1 && d5_2 < d5_1) 
		return (OP_SELL);
   
	return OP_NONE; //нет сигнала
}

// @brief
// @stars **** Old Sidus.
// @info It only in strong trend.
// @old V1 17 signal
// TODO Refactoring
int PSTrendDetector::CurrentSidus(bool isEntry)
{
	const int MABluFast  = 5;
	const int MABluSlow  = 8;
	const int MARedFast  = 16;
	const int MARedSlow  = 28;
	const int MODE_MA    = MODE_EMA;
	const int PRICE_MA   = PRICE_CLOSE;

	double bf=iMA(_symbol, _period, MABluFast, 0, MODE_MA, PRICE_MA, 0);
	double bs=iMA(_symbol, _period, MABluSlow, 0, MODE_MA, PRICE_MA, 0);

	double rf=iMA(_symbol, _period, MARedFast, 0, MODE_MA, PRICE_MA, 0);
	double rs=iMA(_symbol, _period, MARedSlow, 0, MODE_MA, PRICE_MA, 0);

	if (isEntry) 
	{
		if ((rf > rs) && (bf > bs) && (Ask <= bs))  
			return (OP_BUY);   
		
		if ((rf < rs) && (bf < bs) && (Bid >= bs))  
			return (OP_SELL); 
	}
	else
	{	
		if ((bf < bs) && (bs < rf))  
			return OP_SELL;  

		if ((bf > bs) && (bs > rf))  
			return OP_BUY; 
	}
 
   return OP_NONE;
}

// @brief Old SidusSafe
// @stars ****
// @info It only in strong trend, it is better than Sidus.
// @old V1 18 signal
// TODO Refactoring
int PSTrendDetector::CurrentSidusSafe(bool isEntry)
{
	const int MABluFast = 5;
	const int MABluSlow = 8;
	const int MARedFast = 16;
	const int MARedSlow = 28;
	const int MODE_MA = MODE_EMA;
	const int PRICE_MA = PRICE_CLOSE;

	const int RVI_PERIOD = 100; 

	const int K_PERIOD = 8; 
	const int D_PERIOD = 5; 
	const int SLOW = 5; 
	const int METHOD_STOCH = MODE_EMA;

	double bf = iMA(_symbol, _period, MABluFast, 0, MODE_MA, PRICE_MA, 0);
	double bs = iMA(_symbol, _period, MABluSlow, 0, MODE_MA, PRICE_MA, 0);

	double rf = iMA(_symbol, _period, MARedFast, 0, MODE_MA, PRICE_MA, 0);
	double rs = iMA(_symbol, _period, MARedSlow, 0, MODE_MA, PRICE_MA, 0);

	double rvi = iRVI(_symbol, _period, RVI_PERIOD, MODE_MAIN, 0);
	double rvi_signal = iRVI(_symbol, _period, RVI_PERIOD, MODE_SIGNAL, 0);
	
	double stoch = iStochastic(_symbol, _period, K_PERIOD, D_PERIOD, SLOW, METHOD_STOCH, 0, MODE_MAIN, 0);

	if (isEntry) 
	{
		if ((rf > rs) && (bf > bs) && (Ask <= bs) && (rvi >= rvi_signal) && (stoch>50))
			return (OP_BUY);

		if ((rf < rs) && (bf < bs) && (Bid >= bs) && (rvi <= rvi_signal) && (stoch < 50))  
			return (OP_SELL); 
	}
	else
	{	
		if ((bf < bs) && (bs < rf))  
			return (OP_SELL);  

		if ((bf > bs) && (bs > rf))  
			return (OP_BUY); 
	}
 
   return OP_NONE;
}

// @brief Old Wpr
// @stars ***
// @info It is slow. It has good enters. We can use it but necessary optimize it.
// @old V1 22 signal
// TODO Refactoring
int PSTrendDetector::CurrentWpr()
{
	const int m = 20;

	double wpr0 = iWPR(_symbol, _period, m, 0); 
	double wpr1 = iWPR(_symbol, _period, m, 1); 
	double wpr2 = iWPR(_symbol, _period, m, 2); 
		
	if (wpr2 > -80 && wpr1 < -80 && wpr0 > -80) 
		return OP_BUY;

	if (wpr2 < -20 && wpr1 > -20 && wpr0 < -20) 
		return OP_SELL;
   
	return OP_NONE;
}

// @brief Old Wpr2
// @stars ****
// @info It is good. We can use it with Hedge.
// @old V1 23 signal
// TODO Refactoring
int PSTrendDetector::CurrentCalc1Wpr()
{
	const int period = 9;
	int i;
	double wpr0, wpr1;
	int val;
	double Range;
	bool b;	

 	Range=0.0;
	for (i = 0; i <= period; i++) 
	{
		Range = Range + MathAbs(High[i] - Low[i]);
	}
	
	Range = Range / (period+1);

	b = false; 
	i = 0;
	while (i < period && !b)
	{ 
		if (MathAbs(Open[i] - Close[i+1]) >= Range*2.0) 
		{
			b = true; 
		}
		
		i++; 
	}

	if (b) 
	{
		val=(int)MathFloor(period / 3);
	}

	b = false; 
	i = 0;
	while (i < (period - 3) && !b)
	{ 
		if (MathAbs(Close[i + 3] - Close[i]) >= Range * 4.6) 
		{ 
			b = true; 
		}
	
		i++;	
	}
	
	if (b) 
		val=(int)MathFloor(period / 2); 
	else 
		val=period;

	
	wpr0 = 100 - MathAbs(iWPR(_symbol, _period, val, 0)); 
	wpr1 = 100 - MathAbs(iWPR(_symbol, _period, val, 1));
   
	if (wpr0 > 80 && wpr1 < 80) 
		return OP_BUY;
	
	if (wpr0 < 20 && wpr1 > 20) 
		return OP_SELL;
   
	return OP_NONE;
}

// @brief Signal from ZigZag Indicator Old ZigZag
// @stars 
// @info First signal after pick is true.
// @old V2 14 signal
// @TODO it is necessary filter fake signals. Perhaps we may develop this indicator + another one.
int PSTrendDetector::CurrentZigZag()
{
	double firstPeak = 0.0;
	double secondPeak = 0.0;
	int i = 0;
	int totalBars = Bars - 1;

	double peak;
	while (++i < totalBars)
	{
		peak = iCustom(_symbol, _period, "ZigZag", 24, 10, 6, 0, i);
		//peak = iCustom(_symbol, _period, "ZigZag", 20, 10, 3, 0, i);
		//peak = iCustom(_symbol, _periodPlus1, "ZigZag", 12, 5, 3, 0, i); // Original values
		if (peak != 0.0) 
		{
			// Found first up/down.
			if (firstPeak == 0.0) 
			{
				// if first peak appear too late exit.
				if(i > 1)
					return OP_NONE;

				firstPeak = peak;
			}
			else
			{
				// Found second down/up.
				secondPeak = peak;
				break;
			}
		}
	}

	return DetectTrend(secondPeak, firstPeak);
}

// @brief InsideBar signal. D1 only. It should open two surrounding trend B/S stop orders. Old InsideBar
// @stars
// @info 
// @old V2 15 signal
// @url: https://www.mql5.com/en/articles/1771
// @TODO 
int PSTrendDetector::CurrentInsideBar()
{
	const int bar2size = 800;

	//first candle Open price
	double open1 = NormalizeDouble(iOpen(_symbol, _period, 1), _digits);
	//second candle Open price
	double open2 = NormalizeDouble(iOpen(_symbol, _period, 2), _digits);
	//first candle Close price
	double close1 = NormalizeDouble(iClose(_symbol, _period, 1), _digits);
	//second candle Close price
	double close2 = NormalizeDouble(iClose(_symbol, _period, 2), _digits);
	//first candle Low price
	double low1 = NormalizeDouble(iLow(_symbol, _period, 1), _digits);
	//second candle Low price
	double low2 = NormalizeDouble(iLow(_symbol, _period, 2), _digits);
	//first candle High price
	double high1 = NormalizeDouble(iHigh(_symbol, _period, 1), _digits);
	//second candle High price
	double high2 = NormalizeDouble(iHigh(_symbol, _period, 2), _digits);

	double _bar2size=NormalizeDouble(((high2-low2) / Point), 0);

	// if the second bar is bearish, while the first one is bullish
	if(//timeBarInside!=iTime(_symbol,_period,1) && //no orders have been opened at this pattern yet
		_bar2size > bar2size && //the second bar is big enough, so the market is not flat
		open2 > close2 && //the second bar is bullish
		close1 > open1 && //the first bar is bearish
		high2 > high1 &&  //the bar 2 High exceeds the first one's High
		open2 > close1 && //the second bar's Open exceeds the first one's Close
		low2 < low1)      //the second bar's Low is lower than the first one's Low
	{
		return true;
	}
	
	return false;
}

// @brief BUOVB_BEOVB signal. D1 only. It should open stop orders. Old BUOVB_BEOVB
// @stars
// @info BUOVB — Bullish Outside Vertical Bar, BEOVB — Bearish Outside Vertical Bar.
// @old V2 16 signal
// @url: https://www.mql5.com/en/articles/1946
// @TODO 
int PSTrendDetector::CurrentBUOVB_BEOVB()
{
	const int bar1size = 900;                              //Bar 1 Size

	// define prices of necessary bars
	double open1 = NormalizeDouble(iOpen(_symbol, _period, 1), _digits);
	double open2 = NormalizeDouble(iOpen(_symbol, _period, 2), _digits);
	double close1 = NormalizeDouble(iClose(_symbol, _period, 1), _digits);
	double close2 = NormalizeDouble(iClose(_symbol, _period, 2), _digits);
	double low1 = NormalizeDouble(iLow(_symbol, _period, 1), _digits);
	double low2 = NormalizeDouble(iLow(_symbol, _period, 2), _digits);
	double high1 = NormalizeDouble(iHigh(_symbol, _period, 1), _digits);
	double high2 = NormalizeDouble(iHigh(_symbol, _period, 2), _digits);

	double _bar1size=NormalizeDouble(((high1 - low1) / Point),0);
	// Finding bearish pattern BEOVB
	if(//timeBUOVB_BEOVB!=iTime(_symbol,_period,1) && // orders are not yet opened for this pattern 
			_bar1size > bar1size && //first bar is big enough not to consider a flat market
			low1 < low2 &&        //First bar's Low is below second bar's Low
			high1 > high2 &&      //First bar's High is above second bar's High
			close1 < open2 &&     //First bar's Close price is lower than second bar's Open price
			open1 > close1 &&     //First bar is a bearish bar
			open2 < close2)       //Second bar is a bullish bar
	{
		// we have described all conditions indicating that the first bar completely engulfs the second bar and is a bearish bar
		return OP_SELL;
	}

	// Finding bullish pattern BUOVB
	if(//timeBUOVB_BEOVB!=iTime(_symbol,_period,1) && // orders are not yet opened for this pattern 
			_bar1size>bar1size && //first bar is big enough not to consider a flat market
			low1 < low2 &&      //First bar's Low is below second bar's Low
			high1 > high2 &&    //First bar's High is above second bar's High
			close1 > open2 &&   //First bar's Close price is higher than second bar's Open price
			open1 < close1 &&   //First bar is a bullish bar
			open2 > close2)     //Second bar is a bearish bar
	{
		// we have described all conditions indicating that the first bar completely engulfs the second bar and is a bullish bar 
		return OP_BUY;
	}

	return OP_NONE;
}

// @brief EMA.
// @stars
// @info 
// @old V2 17, 18 signal
// @url: https://www.mql5.com/en/articles/1578
// @TODO 
//	case 16: return T1Signal(isEntry, 10, 100);
//	case 17: return T1Signal(isEntry, 30, 200);
int PSTrendDetector::CurrentT1Signal(bool isEntry, int fastMAPeriod, int slowMAPeriod)
{
	const int maMode = MODE_EMA;
	const int maPrice = PRICE_CLOSE;

	double fast1 = iMA(_symbol, _period, fastMAPeriod, 0, maMode, maPrice, 1);
	double fast2 = iMA(_symbol, _period, fastMAPeriod, 0, maMode, maPrice, 2);
	double slow1 = iMA(_symbol, _period, slowMAPeriod, 0, maMode, maPrice, 1);
	double slow2 = iMA(_symbol, _period, slowMAPeriod, 0, maMode, maPrice, 2);

	if (isEntry) 
	{
		if(slow1 > slow2)
		{
			if(fast1 > slow1 && fast2 < slow2)
			{
				return OP_BUY;
			}
		}

		if(slow1 < slow2)
		{
			if(fast1 < slow1 && fast2 > slow2)
			{
				return OP_SELL;
			}
		}
	}
	else
	{
		if(fast1 < slow1) 
			return OP_SELL;
		
		if(fast1 > slow1) 
			return OP_BUY;
	}

	return OP_NONE;
}

// @brief CCI. Old T2Signal
//		case 18: return T2Signal(isEntry, 30, 200);
//		case 19: return T2Signal(isEntry, 90, 100);
// @stars
// @info 
// @old V2 19, 20 signal
// @url: https://www.mql5.com/en/articles/1578
// @TODO 
int PSTrendDetector::CurrentT2Signal(int periodCCI, int levelCCI)
{
	double CCI = iCCI(_symbol, _period, periodCCI, PRICE_TYPICAL, 1);
	double CCILast = iCCI(_symbol, _period, periodCCI, PRICE_TYPICAL, 2);

	if(CCI < levelCCI && CCILast > levelCCI) 
		return OP_SELL;

	if( (CCI > -levelCCI) && (CCILast < -levelCCI)) 
		return OP_BUY;
	
	return OP_NONE;
}

int PSTrendDetector::CurrentT2Signal1()
{
	return CurrentT2Signal(30, 200);
}

int PSTrendDetector::CurrentT2Signal2()
{
	return CurrentT2Signal(90, 100);
}

// @brief 
// @stars
// @info 
// @old V2 21 signal
// @url: https://www.mql5.com/en/articles/1578
// @TODO Refactoring
int PSTrendDetector::CurrentT4Signal()
{
	const double T4_LimitMACD = 0.002;
	const int currentCandle = 1;

	// Enter
	double LMA200 = iMA(_symbol, _period, 200, 0, MODE_EMA, PRICE_OPEN, currentCandle + 1);
	double MA200 = iMA(_symbol, _period, 200, 0, MODE_EMA, PRICE_OPEN, currentCandle);

	double LMA50 = iMA(_symbol, _period, 50, 0, MODE_EMA, PRICE_OPEN, currentCandle + 1);
	double MA50 = iMA(_symbol, _period, 50, 0, MODE_EMA, PRICE_OPEN, currentCandle);

	double LMA10 = iMA(_symbol, _period, 10, 0, MODE_EMA, PRICE_OPEN, currentCandle + 1);
	double MA10 = iMA(_symbol, _period, 10, 0, MODE_EMA, PRICE_OPEN, currentCandle);

	double LMACD = iMACD(_symbol, _period, 12, 26, 9, PRICE_OPEN, MODE_MAIN, currentCandle + 1);
	double MACD = iMACD(_symbol, _period, 12, 26, 9, PRICE_OPEN, MODE_MAIN, currentCandle);

	if(MA200 > LMA200)
	{
		if(MA50 > LMA50 && MA50>MA200) 
		{
			if(MA10 > LMA10 && MA10>MA50) 
			{
				if(MACD > LMACD && MACD > T4_LimitMACD) 
					return OP_BUY;
			}
		}
	} 
	else 
	{
		if(MA200 < LMA200) 
		{
			if(MA50 < LMA50 && MA50 < MA200) 
			{
				if(MA10 < LMA10 && MA10 < MA50) 
				{
					if(MACD < LMACD && MACD < -T4_LimitMACD)
						return OP_SELL;
				}
			}
		}
	}
	
	return OP_NONE;
}

bool PSTrendDetector::Get_RAVI(int Number, string symbol,int timeframe, 
              bool NullBarRecount, int Period1, int Period2, 
              int MA_Metod,  int  PRICE)
{
	int IBARS = iBars(symbol, timeframe);  
	
	if(IBARS < MathMax(Period1, Period2))
		return(false);
	
	static int IndCounted[]; 
	if(ArraySize(IndCounted) < Number + 1)
	{
		ArrayResize(IndCounted, Number + 1); 
		ArrayResize(RAVI_Buffer,Number + 1); 
	}

	int LastCountBar = 0;
	
	if(!NullBarRecount)
		LastCountBar = 1;

	double MA1, MA2, result; 
	int MaxBar, bar, limit, counted_bars = IndCounted[Number];
	
	IndCounted[Number] = IBARS - 1;
	limit = IBARS - counted_bars - 1;
	MaxBar = IBARS - 1 - MathMax(Period1, Period2); 
	
	if(limit > MaxBar)
	{
		limit=MaxBar;
		ArrayInitialize(RAVI_Buffer, 0.0);
	}

	for(bar = limit; bar >= LastCountBar; bar--)
	{ 
		MA1 = iMA(symbol, timeframe, Period1, 0, MA_Metod, PRICE, bar); 
		MA2 = iMA(symbol, timeframe, Period2, 0, MA_Metod, PRICE, bar); 

		result = ((MA1 - MA2) / MA2)*100; 
		if((bar > 0) && (bar <= 4))
		{ 
			RAVI_Buffer[Number][4] = RAVI_Buffer[Number][3];
			RAVI_Buffer[Number][3] = RAVI_Buffer[Number][2];
			RAVI_Buffer[Number][2] = RAVI_Buffer[Number][1];	    	    
			RAVI_Buffer[Number][1] = result;
		}

		if(bar == 0)
			RAVI_Buffer[Number][0] = result; 	 
	} 
	
	return true;
}

bool PSTrendDetector::Get_ASCTrend1(int Number, string symbol,int timeframe, 
                   bool NullBarRecount, int RISK)
{
	int IBARS = iBars(symbol, timeframe);  
	if((IBARS < 3 + RISK*2 + 1) || (IBARS < 10))
		return(false);
	
	static double x1[], x2[];
	static int IndCounted[]; 
	
	if(ArraySize(IndCounted) < Number + 1)
	{
		ArrayResize(x1, Number + 1); 
		ArrayResize(x2, Number + 1); 
		ArrayResize(IndCounted, Number + 1); 
		ArrayResize(ASCTrend1_Buffer, Number + 1); 
	}

	int LastCountBar = 0;
	if(!NullBarRecount)
		LastCountBar = 1;
	double value2, val1, val2;
	double TrueCount, Range, AvgRange, MRO1, MRO2;
	int MaxBar, iii, bar, value10, value11, 
		counted_bars = IndCounted[Number];

	IndCounted[Number] = IBARS - 1;
	value10 = 3 + RISK*2;
	bar = IBARS - counted_bars - 1; 
	MaxBar = IBARS - 1 - value10;
	if(bar > MaxBar)
	{
		bar = MaxBar;
		x1[Number] = 67 + RISK;
		x2[Number] = 33 - RISK;
		ArrayInitialize(ASCTrend1_Buffer, 0.0); 
	}

	while(bar >= LastCountBar)
	{  
		Range = 0.0;
		AvgRange = 0.0;

		for(iii = 0; iii <= 9; iii++) 
			AvgRange += MathAbs(iHigh(symbol, timeframe, bar + iii) -
				iLow(symbol, timeframe, bar + iii));
		
		Range=AvgRange / 10;
		iii = 0;
		TrueCount = 0;
		while(iii < 9 && TrueCount < 1)
		{
			if(MathAbs(iOpen(symbol, timeframe, bar + iii) - 
				iClose(symbol, timeframe, bar + iii)) >= Range*2.0) 
					TrueCount++;

			iii++;
		}

		if(TrueCount >= 1)
			MRO1 = bar + iii; 
		else 
			MRO1 = -1;

		iii = 0;
		TrueCount = 0;
		while(iii < 6 && TrueCount < 1)
		{
			if(MathAbs(iClose(symbol, timeframe, bar + iii + 3) - 
				iClose(symbol, timeframe, bar + iii)) >= Range*4.6) 
			TrueCount++;

			iii++;
		}
		if(TrueCount >= 1)
			MRO2 = bar + iii; 
		else 
			MRO2 = -1;

		if(MRO1 > -1)
			value11 = 3; 
		else 
			value11 = value10;
		
		if(MRO2 > -1)
			value11 = 4; 
		else 
			value11 = value10;

		value2 = 100 - MathAbs(iWPR(symbol, timeframe, value11, bar));

		val1 = 0;
		val2 = 0;

		if(value2 > x1[Number])
		{
			val1 = iLow (symbol, timeframe, bar);
			val2 = iHigh(symbol, timeframe, bar);
		}

		if(value2 < x2[Number])
		{
			val1 = iHigh(symbol, timeframe, bar);
			val2 = iLow (symbol, timeframe, bar);
		} 

		if(bar == 1) 
			ASCTrend1_Buffer[Number][1] = val2 - val1;

		if(bar == 0)
			ASCTrend1_Buffer[Number][0] = val2 - val1;
		
		bar--;
	}

	return true;
}

// @brief ASC_RAVI
// @stars
// @info 
// @old V2 22 signal
// @url: https://www.mql5.com/en/articles/1463
// @TODO 
int PSTrendDetector::ASCT_RAVI()
{
	const int RAVI_Timeframe = _period;
	const int ASCT_Timeframe = _periodPlus1;
	const int RISK_Up = 3;
	const int RISK_Dn = 3;
	const int Period1_Up = 7; 
	const int Period2_Up = 65; 
	const int Period1_Dn = 7; 
	const int Period2_Dn = 65; 
	const int MA_Metod_Up = 0; // 0 MODE_SMA, 1 MODE_EMA, 2 MODE_SMMA, 3 MODE_LWMA
	const int PRICE_Up = 0; // 0 PRICE_CLOSE, 1 PRICE_OPEN, 2 PRICE_HIGH, 3 PRICE_LOW, 4 PRICE_MEDIAN, 5 PRICE_TYPICAL, 6 PRICE_WEIGHTED
	const int MA_Metod_Dn = 0;
	const int PRICE_Dn = 0;

	if(iBars(_symbol, ASCT_Timeframe) < 3 + RISK_Up*2 + 1 + 1)
		return OP_NONE;

	if(iBars(_symbol, ASCT_Timeframe) < 3 + RISK_Dn*2 + 1 + 1)
		return OP_NONE;

	if(iBars(_symbol, RAVI_Timeframe) < MathMax(Period1_Up, Period2_Up + 4))
		return OP_NONE;

	if (iBars(_symbol, RAVI_Timeframe) < MathMax(Period1_Dn, Period2_Dn+4))
		return OP_NONE;

	int bar;

	Get_RAVI(0, _symbol, RAVI_Timeframe, false, Period1_Up, Period2_Up, MA_Metod_Up, PRICE_Up);
	for(bar = 3; bar >= 0; bar--)
		RAVI_Up[bar] = RAVI_Buffer[0][bar];

	Get_ASCTrend1(0, _symbol, ASCT_Timeframe, false, RISK_Up);
		ASCTrend1_Up[1] = ASCTrend1_Buffer[0][1];  

	Get_RAVI(1, _symbol, RAVI_Timeframe, false, Period1_Dn, Period2_Dn, MA_Metod_Dn, PRICE_Dn);
	for(bar = 3; bar >= 0; bar--)
		RAVI_Dn[bar] = RAVI_Buffer[1][bar];

	Get_ASCTrend1(1, _symbol, ASCT_Timeframe, false, RISK_Dn); 
		ASCTrend1_Dn[1] = ASCTrend1_Buffer[1][1]; 

	if(RAVI_Up[2] - RAVI_Up[3] < 0)
		if(RAVI_Up[1] - RAVI_Up[2] > 0)
			if(ASCTrend1_Up[1] > 0)
				return OP_BUY;

	if(RAVI_Dn[2] - RAVI_Dn[3] > 0)
		if(RAVI_Dn[1] - RAVI_Dn[2] < 0)
			if(ASCTrend1_Dn[1] < 0)
				return OP_SELL;

	return OP_NONE;
}

// @brief HLHB Forex Trend-Catcher System
//		case 22: return HLHBTrendCatcher(isEntry, false, false);
//		case 23: return HLHBTrendCatcher(isEntry, true, false);
//		case 24: return HLHBTrendCatcher(isEntry, false, true);
//		case 25: return HLHBTrendCatcher(isEntry, true, true);
// @stars
// @info 
// @old V2 23, 24, 25, 26 signal
// @url: https://www.babypips.com/trading/forex-hlhb-system-explained
// @TODO 
int PSTrendDetector::CurrentHLHBTrendCatcher(bool checkADX, bool checkMACD)
{
	const int bar2 = 2;
	const int bar1 = 1;
	const int fastMAPeriod = 5;
	const int slowMAPeriod = 10;
	const int rsiPeriod = 10;
	const double rsiCentre = 50.0;
	double macd2 = 0.0;
	double macd1 = 0.0;
	
	if(checkADX)
	{
		// https://www.babypips.com/trading/forex-hlhb-system-20170203
		double adx1 = NormalizeDouble(iADX(_symbol, _period, 14, PRICE_CLOSE, MODE_MAIN, bar1), 4);
		
		if (adx1 < 25)
			return OP_NONE;
	}

	if (checkMACD) 
	{
		// https://forums.babypips.com/t/amazing-crossover-system-100-pips-per-day/19403/14
		macd2 = iMACD(_symbol, _period, 5, 9, 4, PRICE_CLOSE, MODE_MAIN, 2);
		macd1 = iMACD(_symbol, _period, 5, 9, 4, PRICE_CLOSE, MODE_MAIN, 1);
	}
	
	double maFast2 = NormalizeDouble(iMA(_symbol, _period, fastMAPeriod, 0, MODE_EMA, PRICE_CLOSE, bar2), _digits);
	double maFast1 = NormalizeDouble(iMA(_symbol, _period, fastMAPeriod, 0, MODE_EMA, PRICE_CLOSE, bar1), _digits);
	
	double maSlow2 = NormalizeDouble(iMA(_symbol, _period, slowMAPeriod, 0, MODE_EMA, PRICE_CLOSE, bar2), _digits);
	double maSlow1 = NormalizeDouble(iMA(_symbol, _period, slowMAPeriod, 0, MODE_EMA, PRICE_CLOSE, bar1), _digits);

	double rsi2 = NormalizeDouble(iRSI(_symbol, _period, rsiPeriod, PRICE_MEDIAN, bar2), 0);
	double rsi1 = NormalizeDouble(iRSI(_symbol, _period, rsiPeriod, PRICE_MEDIAN, bar1), 0);

	//Print(StringConcatenate("\tmaFast2\t", maFast2, "\tmaFast1\t", maFast1, "\tmaSlow2\t", maSlow2, "\tmaSlow1\t", maSlow1, "\trsi2\t", rsi2, "\trsi1\t", rsi1));

	if((maFast2 < maSlow2 || maFast2 == maSlow2) 
		&& (maFast1 > maSlow1 || maFast1 == maSlow1))
	{
		if (rsi2 <= rsiCentre && rsi1 >= rsiCentre && rsi2 < rsi1)
		{
			if(checkMACD && !(macd2 < 0 && macd1 > 0))
			{
				return OP_NONE;
			}

			return OP_BUY;
		}
	}

	if((maFast2 > maSlow2 ||  maFast2 == maSlow2)
		&& (maFast1 < maSlow1 || maFast1 == maSlow1))
	{
		if (rsi2 >= rsiCentre && rsi1 <= rsiCentre && rsi2 > rsi1)
		{
			if(checkMACD && !(macd2 > 0 && macd1 < 0))
			{
				return OP_NONE;
			}

			return OP_SELL;
		}
	}

	return OP_NONE;
}

// @brief Short term bollinger reversion strategy
// @stars
// @info 
// @old V2 27 signal
// @url: https://www.babypips.com/trading/system-rules-short-term-bollinger-reversion-strategy
// @TODO 
int PSTrendDetector::CurrentSTBollingerRev()
{
	const int bandPeriod = 50;
	const double bandDeviation = 2.0;
	const int rsiPeriod = 9;
	const double rsiHigh = 75.0;
	const double rsiLow = 25.0;
	
	double bandUpper1 = NormalizeDouble(iBands(_symbol, _period, bandPeriod, bandDeviation, 0, PRICE_CLOSE, MODE_UPPER, 1), _digits);
	double bandMain1 = NormalizeDouble(iBands(_symbol, _period, bandPeriod, bandDeviation, 0, PRICE_CLOSE, MODE_MAIN, 1), _digits);
	double bandLower1 = NormalizeDouble(iBands(_symbol, _period, bandPeriod, bandDeviation, 0, PRICE_CLOSE, MODE_LOWER, 1), _digits);

	double rsi1 = iRSI(_symbol, _period, rsiPeriod, PRICE_CLOSE, 1);

	double high1 = iHigh(_symbol, _period, 1);
	double low1 = iLow(_symbol, _period, 1);
	double close1 = iClose(_symbol, _period, 1);

	if (high1 >= bandUpper1 && close1 < bandUpper1 && rsi1 > rsiHigh) 
	{
		return OP_BUY;
	}
	
	if (low1 <= bandLower1 && close1 > bandLower1 && rsi1 < rsiLow) 
	{
		return OP_SELL;
	}

	return OP_NONE;
}

// @brief SMA Crossover Pullback
// @stars
// @info 
// @old V2 28 signal
// @url: https://www.babypips.com/trading/forex-system-20150605
// @TODO 
int PSTrendDetector::CurrentSMACrossoverPullback()
{
	const int maFastPeriod = 100;
	const int maSlowPeriod = 200;

	const int stKPeriod = 14;
	const int stDPeriod = 3;
	const int stSlowing = 3;
	const int stPrice = 0; // 0 - Low/High or 1 - Open/Close

	if (_smaCrossoverPullbackCross == 0) 
	{
		double maFast2 = NormalizeDouble(iMA(_symbol, _period, maFastPeriod, 0, MODE_SMA, PRICE_CLOSE, 2), _digits);
		double maFast1 = NormalizeDouble(iMA(_symbol, _period, maFastPeriod, 0, MODE_SMA, PRICE_CLOSE, 1), _digits);

		double maSlow2 = NormalizeDouble(iMA(_symbol, _period, maSlowPeriod, 0, MODE_SMA, PRICE_CLOSE, 2), _digits);
		double maSlow1 = NormalizeDouble(iMA(_symbol, _period, maSlowPeriod, 0, MODE_SMA, PRICE_CLOSE, 1), _digits);

		if((maFast2 < maSlow2 || maFast2 == maSlow2) 
			 	&& (maFast1 > maSlow1 || maFast1 == maSlow1))
		{
			// Buy
			_smaCrossoverPullbackCross = 1;
		}

		if((maFast2 > maSlow2 ||  maFast2 == maSlow2)
				&& (maFast1 < maSlow1 || maFast1 == maSlow1))
		{
			// Sell
			_smaCrossoverPullbackCross = 2;
		}

		return OP_NONE;
	}
	
	double stochastic1 = NormalizeDouble(iStochastic(_symbol, _period, stKPeriod, stDPeriod, stSlowing, MODE_SMA, stPrice, MODE_MAIN, 1), 2);

	if (_smaCrossoverPullbackCross == 1 && stochastic1 <= 25.0) 
	{
		_smaCrossoverPullbackCross = 0;

		return OP_BUY;
	}
	
	if (_smaCrossoverPullbackCross == 2 && stochastic1 >= 75.0) 
	{
		_smaCrossoverPullbackCross = 0;

		return OP_SELL;
	}

	return OP_NONE;
}

// @brief The 3 Duck’s Trading System H1 only.
// @stars
// @info 
// @old V2 29 signal
// @url: https://forums.babypips.com/t/the-3-ducks-trading-system/6430
// @TODO 
int PSTrendDetector::The3Ducks()
{
	const int maPeriod = 60;
	const int tfCount = 3;
	int tf[3];
	tf[0] = _periodPlus1; // H4
	tf[1] = _period; // H1
	tf[2] = PERIOD_M5; // M5
	// tf[0] = PERIOD_H4; // H4
	// tf[1] = PERIOD_H1; // H1
	// tf[2] = PERIOD_M5; // M5

	bool lastIsUp = false;

	// Check all TF in in one direction.
	for(int i = 0; i < 3; i++)
	{
		int period = tf[i];
		double ma1 = NormalizeDouble(iMA(_symbol, period, maPeriod, 0, MODE_SMA, PRICE_CLOSE, 1), _digits);
		double high1 = iHigh(_symbol, period, 1);
		double low1 = iLow(_symbol, period, 1);

		// The price is between high and low.
		if (low1 <= ma1 && ma1 <= high1) {
			return OP_NONE;
		}
		
		bool isUp = ma1 > high1;
		if (i == 0) {
			lastIsUp = isUp;
		}
		else {
			// This TF is in different direction.
			if (lastIsUp != isUp) {
				return OP_NONE;
			}
		}
	}

	if (lastIsUp) {
		return OP_SELL;
	}
	else {
		return OP_BUY;
	}
	
	return OP_NONE;
}

// @brief Trend detector with MA. It works with TF +1. Old AboveTrendDetectorMA
// @stars
// @info 
// @TODO 
int PSTrendDetector::High2MA3()
{
	const int maTF = _periodPlus1;
	const int maPeriod = 3;

	int currentBar = iBars(_symbol, maTF);

	if (currentBar != _highMA1Data.LastBarNumber) 
	{
		_highMA1Data.LastBarNumber = currentBar;
		// Get trend
		double ma2 = NormalizeDouble(iMA(_symbol, maTF, maPeriod, 0, MODE_LWMA, PRICE_WEIGHTED, 2), _digits);
		double ma1 = NormalizeDouble(iMA(_symbol, maTF, maPeriod, 0, MODE_LWMA, PRICE_WEIGHTED, 1), _digits);

		_highMA1Data.CurrentTrend = DetectTrend(ma1, ma2);
	}

	return _highMA1Data.CurrentTrend;
}

// @brief Old MA3
// @stars ****
// @info It looks good necessary more tests.
// @old V1 16 signal
// TODO Refactoring
int PSTrendDetector::High4MA4_8()
{
	const int tf = _periodPlus1;
	const int w4 = 4, w8 = 8;
	
	int currentBars = iBars(_symbol, tf);

	if (currentBars != _highMA3Data.LastBarNumber) 
	{
		_highMA3Data.LastBarNumber = currentBars;

		//w4_0 = iMA(NULL, PERIOD_W1, w4, 0, MODE_SMA, PRICE_CLOSE, 0);
		double w4_0 = iMA(_symbol, tf, w4, 0, MODE_SMA, PRICE_CLOSE, 0);
		double w4_1 = iMA(_symbol, tf, w4, 0, MODE_SMA, PRICE_CLOSE, 1);
		double w8_0 = iMA(_symbol, tf, w8, 0, MODE_SMA, PRICE_CLOSE, 0);
		double w8_1 = iMA(_symbol, tf, w8, 0, MODE_SMA, PRICE_CLOSE, 1);

		_highMA3Data.CurrentTrend = DetectTrend(w4_0, w4_1, w8_0, w8_1);
	}

	return _highMA3Data.CurrentTrend;
}

// @brief Trend detector with MAMA_NK indicator. It works with TF +1. Old AboveTrendDetectorMAMANK
// @stars
// @info 
// @TODO 
int PSTrendDetector::High1MAMANK()
{
	const int maTF = _periodPlus1;
	const double fastLimit = 0.5;
	const double slowLimit = 0.05;
	const int ipcx = 9; /* Selecting prices, upon which the indicator will be calculated (0-CLOSE, 1-OPEN, 2-HIGH, 3-LOW, 4-MEDIAN, 5-TYPICAL, 6-WEIGHTED, 7-Heiken Ashi Close, 
		8-SIMPL, 9-TRENDFOLLOW, 10-0.5*TRENDFOLLOW, 11-Heiken Ashi Low, 12-Heiken Ashi High, 13-Heiken Ashi Open, 14-Heiken Ashi Close, 15-Heiken Ashi Open0.) */
	int currentBars = iBars(_symbol, maTF);

	if (currentBars != _highMAMANKData.LastBarNumber) 
	{
		_highMAMANKData.LastBarNumber = currentBars;
		// Get trend
		double fama1 = NormalizeDouble(iCustom(_symbol, maTF, IndicatorNameMAMA_NK, fastLimit, slowLimit, ipcx, 0, 1), _digits);
		double mama1 = NormalizeDouble(iCustom(_symbol, maTF, IndicatorNameMAMA_NK, fastLimit, slowLimit, ipcx, 1, 1), _digits);

		_highMAMANKData.CurrentTrend = DetectTrend(mama1, fama1);
	}

	return _highMAMANKData.CurrentTrend;
}

// @brief EXPERT ADVISORS BASED ON POPULAR TRADING SYSTEMS AND ALCHEMY OF TRADING ROBOT OPTIMIZATION
//			Expert 11 modified
// @stars
// @info Use MA H4 for big trend. Moving Average of Oscillator H1 for current trend.
// @old V2 30 signal
// @url: https://www.mql5.com/en/articles/1525
// @TODO 
int PSTrendDetector::CurrentExp11M()
{
	const int osmaFast = 12;
	const int osmaSlow = 26;
	const int osmaMACDSma = 9;
	
	double osma2 = iOsMA(_symbol, _period, osmaFast, osmaSlow, osmaMACDSma, PRICE_CLOSE, 2);
	double osma1 = iOsMA(_symbol, _period, osmaFast, osmaSlow, osmaMACDSma, PRICE_CLOSE, 1);

	if (osma2 < 0 && osma1 > 0)
	{
		return OP_BUY;
	}

	if (osma2 > 0 && osma1 < 0)
	{
		return OP_SELL;
	}

	return OP_NONE;
}

// @brief EXPERT ADVISORS BASED ON POPULAR TRADING SYSTEMS AND ALCHEMY OF TRADING ROBOT OPTIMIZATION
//			Expert 11
// @stars
// @info It isn't added.
// @old V2 XX signal
// @url: https://www.mql5.com/en/articles/1525
// @TODO 
int PSTrendDetector::Exp11(bool isEntry)
{
	int    Timeframe_Up = _period;
	int    Timeframe_Dn = _period;
	int    TimeframeX_Up = _periodPlus1;
	int    TimeframeX_Dn = _periodPlus1;
	int    Length1X_Up = 4;  // depth of the first smoothing
	int    Phase1X_Up = 100; // parameter of the first smoothing
		//changing in the range -100 ... +100, influences the quality of the transient process of averaging;  
	int    Length2X_Up = 4;  // depth of the second smoothing 
	int    Phase2X_Up = 100; // parameter of the second smoothing, 
		//changing in the range -100 ... +100, influences the quality  of the transient process of averaging;  
	int    IPCX_Up = 0;/* Selecting prices on which the indicator will be calculated (0-CLOSE, 1-OPEN, 2-HIGH, 3-LOW, 4-MEDIAN, 5-TYPICAL, 6-WEIGHTED, 
	7-Heiken Ashi Close, 8-SIMPL, 9-TRENDFOLLOW, 10-0.5*TRENDFOLLOW, 11-Heiken Ashi Low, 12-Heiken Ashi High, 13-Heiken Ashi Open, 14-Heiken Ashi Close.) */
	double IndLevel_Up = 0; // breakout level of the indicator
	int    FastEMA_Up = 12;  // quick EMA period
	int    SlowEMA_Up = 26;  // slow EMA period
	int    SignalSMA_Up = 9;  // signal SMA period
	int    STOPLOSS_Up = 50;  // stop loss
	int    PriceLevel_Up =40; // difference between the curre	int MinBarX_Up, MinBar_Up, MinBarX_Dn, MinBar_Dn;
	double IndLevel_Dn = 0; // breakout level of the indicator
	int    FastEMA_Dn = 12;  // quick EMA period
	int    SlowEMA_Dn = 26;  // slow EMA period
	int    SignalSMA_Dn = 9;  // signal SMA period
	int    PriceLevel_Dn = 40;
	int    Length1X_Dn = 4;  // smoothing depth 
	int    Phase1X_Dn = 100;  // parameter of the first smoothing        //changing in the range -100 ... +100, influences the quality       //of the transient process of averaging;  
	int    Length2X_Dn = 4;  // smoothing depth 
	int    Phase2X_Dn = 100; // parameter of the second smoothing        //changing in the range -100 ... +100, influences the quality        //of the transient process of averaging;  
   int    IPCX_Dn = 0;/* Selecting prices on which the indicator will be calculated (0-CLOSE, 1-OPEN, 2-HIGH, 3-LOW, 4-MEDIAN, 5-TYPICAL, 6-WEIGHTED, 7-Heiken Ashi Close, 
            8-SIMPL, 9-TRENDFOLLOW, 10-0.5*TRENDFOLLOW, 11-Heiken Ashi Low, 12-Heiken Ashi High, 13-Heiken Ashi Open, 14-Heiken Ashi Close.) */	

	static double TrendX_Up, TrendX_Dn;
	static datetime StopTime_Up, StopTime_Dn; 
	static int LastBars_Up, LastBarsX_Up, LastBarsX_Dn, LastBars_Dn;

	double J2JMA1, J2JMA2, Osc1, Osc2;
	int MinBarX_Up, MinBar_Up, MinBarX_Dn, MinBar_Dn;
	MinBar_Up  = 3 + MathMax(FastEMA_Up, SlowEMA_Up) + SignalSMA_Up;
	MinBarX_Up  = 3 + 30 + 30;
	MinBar_Dn  = 3 + MathMax(FastEMA_Dn, SlowEMA_Dn) + SignalSMA_Dn;
	MinBarX_Dn  = 3 + 30 + 30;   
	
	int IBARS_Up = iBars(NULL, Timeframe_Up);
	int IBARSX_Up = iBars(NULL, TimeframeX_Up);
	
	if (IBARS_Up >= MinBar_Up && IBARSX_Up >= MinBarX_Up)
	{
		//----+ DEFINING TREND         |
		if (LastBarsX_Up != IBARSX_Up)
		{
			//----+ Initialization of variables 
			LastBarsX_Up = IBARSX_Up;
			
			//----+ calculating indicator values for J2JMA   
			J2JMA1 = iCustom(NULL, TimeframeX_Up, 
								"J2JMA", Length1X_Up, Length2X_Up,
												Phase1X_Up, Phase2X_Up,  
														0, IPCX_Up, 0, 1);
			//---                     
			J2JMA2 = iCustom(NULL, TimeframeX_Up, 
								"J2JMA", Length1X_Up, Length2X_Up,
												Phase1X_Up, Phase2X_Up,  
														0, IPCX_Up, 0, 2);
			
			//----+ defining trend
			TrendX_Up = J2JMA1 - J2JMA2;
			//----+ defining a signal for closing trades
			if (TrendX_Up < 0 && !isEntry)
				return OP_BUY;                                      
		}
		
		if (LastBars_Up != IBARS_Up)
		{
			LastBars_Up = IBARS_Up;
			StopTime_Up = iTime(NULL, Timeframe_Up, 0)
											+ 60 * Timeframe_Up;
			//----+ calculating indicator values
			Osc1 = iCustom(NULL, Timeframe_Up, 
							"5c_OsMA", FastEMA_Up, SlowEMA_Up,
												SignalSMA_Up, 5, 1);
			//---                   
			Osc2 = iCustom(NULL, Timeframe_Up, 
							"5c_OsMA", FastEMA_Up, SlowEMA_Up,
												SignalSMA_Up, 5, 2);
			
			//----+ defining signals for trades
			if (TrendX_Up > 0)                                           
			if (Osc2 < IndLevel_Up)
				if (Osc1 > IndLevel_Up && isEntry)
					return OP_BUY;
		}
	}
	
	int IBARS_Dn = iBars(NULL, Timeframe_Dn);
	int IBARSX_Dn = iBars(NULL, TimeframeX_Dn);
	
	if (IBARS_Dn >= MinBar_Dn && IBARSX_Dn >= MinBarX_Dn)
	{
		//----+ DEFINING TREND         |
		if (LastBarsX_Dn != IBARSX_Dn)
		{
			//--- Initialization of variables 
			LastBarsX_Dn = IBARSX_Dn;
			
			//----+ calculating indicator values for J2JMA   
			J2JMA1 = iCustom(NULL, TimeframeX_Dn, 
								"J2JMA", Length1X_Dn, Length2X_Dn,
												Phase1X_Dn, Phase2X_Dn,  
														0, IPCX_Dn, 0, 1);
			//---                     
			J2JMA2 = iCustom(NULL, TimeframeX_Dn, 
								"J2JMA", Length1X_Dn, Length2X_Dn,
												Phase1X_Dn, Phase2X_Dn,  
														0, IPCX_Dn, 0, 2);
			
			//----+ defining trend                                 
			TrendX_Dn = J2JMA1 - J2JMA2;
			//----+ defining a signal for closing trades
			if (TrendX_Dn > 0 && !isEntry)
				return OP_SELL;    
		}
		
		//----+ +----------------------------------------+
		//----+ DEFINING SIGNAL FOR MARKET ENTERING      |
		//----+ +----------------------------------------+
		if (LastBars_Dn != IBARS_Dn)
		{
			//----+ Initialization of variables 
			LastBars_Dn = IBARS_Dn;
			StopTime_Dn = iTime(NULL, Timeframe_Dn, 0)
											+ 60 * Timeframe_Dn;
			//----+ calculating indicator values    
			Osc1 = iCustom(NULL, Timeframe_Dn, 
							"5c_OsMA", FastEMA_Dn, SlowEMA_Dn,
												SignalSMA_Dn, 5, 1);
			//---                   
			Osc2 = iCustom(NULL, Timeframe_Dn, 
							"5c_OsMA", FastEMA_Dn, SlowEMA_Dn,
												SignalSMA_Dn, 5, 2);
			
			//----+ defining signals for trades
			if (TrendX_Dn < 0)                                           
			if (Osc2 > IndLevel_Dn)
				if (Osc1 < IndLevel_Dn && isEntry)
						return OP_SELL;                            
		}
	}

	return -1;
}

// @brief EXPERT ADVISORS BASED ON POPULAR TRADING SYSTEMS AND ALCHEMY OF TRADING ROBOT OPTIMIZATION
//			Expert 12, Expert 13 (filtered) modified
// @stars
// @info 
// @old V2 31, 32 signal
// @url: https://www.mql5.com/en/articles/1525
// @TODO 
int PSTrendDetector::CurrentJtatl4()
{
	const int jfLength = 4;
	const int jfPhase = 100;
	const int jfIPC = 0; /* Selecting prices, upon which the indicator will be calculated (0-CLOSE, 1-OPEN, 2-HIGH, 3-LOW, 4-MEDIAN, 5-TYPICAL, 6-WEIGHTED, 
		7-Heiken Ashi Close, 8-SIMPL, 9-TRENDFOLLOW, 10-0.5*TRENDFOLLOW, 11-Heiken Ashi Low, 12-Heiken Ashi High, 13-Heiken Ashi Open, 14-Heiken Ashi Close.) */

	double mov[3];
	mov[0] = 0;
	for(int bar = 1; bar <= 3; bar++)
	{
		mov[bar - 1]=                  
			iCustom(_symbol, _period, IndicatorNameJFatl, jfLength, jfPhase, 0, jfIPC, 0, bar);
	}

	double mov12 = mov[0] - mov[1];
	double mov23 = mov[1] - mov[2];

	if (mov23 < 0 && mov12 > 0)
	{
		return OP_BUY;
	}

	if (mov23 > 0 && mov12 < 0)
	{
		return OP_SELL;
	}

	return OP_NONE;
}

// @brief EXPERT ADVISORS BASED ON POPULAR TRADING SYSTEMS AND ALCHEMY OF TRADING ROBOT OPTIMIZATION
//			Expert 14, Expert 15 (filtered) modified
// @stars
// @info 
// @old V2 31, 32 signal
// @url: https://www.mql5.com/en/articles/1525
// @TODO 
int PSTrendDetector::CurrentExp14M()
{
	const int length = 8; // depth of JJMA smoothing for the entry price
	const int xLength = 8;  // depth of JurX smoothing for the obtained indicator 
	const int phase = 100;
	const int ipc = 0; /* Selecting prices, upon which the indicator will be calculated (0-CLOSE, 1-OPEN, 2-HIGH, 3-LOW, 4-MEDIAN, 5-TYPICAL, 6-WEIGHTED, 
		7-Heiken Ashi Close, 8-SIMPL, 9-TRENDFOLLOW, 10-0.5*TRENDFOLLOW, 11-Heiken Ashi Low, 12-Heiken Ashi High, 13-Heiken Ashi Open, 14-Heiken Ashi Close.) */

	double mov[3];
	mov[0] = 0;
	for(int bar = 1; bar <= 3; bar++)
	{
		mov[bar - 1]=                  
			iCustom(_symbol, _period, IndicatorNameJCCIX, length, xLength, phase, ipc, 0, bar);
	}

	double mov12 = mov[0] - mov[1];
	double mov23 = mov[1] - mov[2];

	if (mov23 < 0 && mov12 > 0)
	{
		return OP_BUY;
	}

	if (mov23 > 0 && mov12 < 0)
	{
		return OP_SELL;
	}

	return OP_NONE;
}

// @brief Trend detector with MAMA_NK indicator. It works with TF +1. Old AboveTrendDetectorStepMAStoch
// @stars
// @info 
// @TODO 
int PSTrendDetector::High1StepMAStoch()
{
	const int maTF = _periodPlus1;
	const int periodWATR = 10; 
	const double kwatr = 1.0000; 
	const int highLow = 0; 

	int currentBar = iBars(_symbol, maTF);

	if (currentBar != _highStepMAStochData.LastBarNumber) 
	{
		_highStepMAStochData.LastBarNumber = currentBar;
		// Get trend
		double fast = NormalizeDouble(iCustom(_symbol, maTF, IndicatorNameStepMAStoch, periodWATR, kwatr, highLow, 0, 1), _digits);
		double slow = NormalizeDouble(iCustom(_symbol, maTF, IndicatorNameStepMAStoch, periodWATR, kwatr, highLow, 1, 1), _digits);

		_highStepMAStochData.CurrentTrend = DetectTrend(fast, slow);
	}

	return _highStepMAStochData.CurrentTrend;
}

// @brief Trend detector with J2JMA indicator. It works with TF +1. Old AboveTrendDetectorStepMAStoch
// @stars
// @info 
// @TODO 
int PSTrendDetector::High1J2JMA()
{
	const int maTF = _periodPlus1;
	const int length1 = 4; // depth of the first smoothing
	const int phase1 = 100; // parameter of the first smoothing changing in the range -100 ... +100, influences the quality of the transient process of averaging;  
	const int length2 = 4; // depth of the second smoothing 
	const int phase2 = 100; /* Selecting prices on which the indicator will be calculated (0-CLOSE, 1-OPEN, 2-HIGH, 3-LOW, 4-MEDIAN, 5-TYPICAL, 6-WEIGHTED, 
	7-Heiken Ashi Close, 8-SIMPL, 9-TRENDFOLLOW, 10-0.5*TRENDFOLLOW, 11-Heiken Ashi Low, 12-Heiken Ashi High, 13-Heiken Ashi Open, 14-Heiken Ashi Close.) */
	const int ips = 0; 

	int currentBar = iBars(_symbol, maTF);

	if (currentBar != _highJ2JMA.LastBarNumber) 
	{
		_highJ2JMA.LastBarNumber = currentBar;
		// Get trend
		double d1 = iCustom(_symbol, maTF, IndicatorNameJ2JMA, length1, length2, phase1, phase2, 0, ips, 0, 1);
		double d2 = iCustom(_symbol, maTF, IndicatorNameJ2JMA, length1, length2, phase1, phase2, 0, ips, 0, 2);

		_highJ2JMA.CurrentTrend = DetectTrend(d1, d2);
	}

	return _highJ2JMA.CurrentTrend;
}

// @brief Noise detector with MA indicator. It works on 2 TF below. Old NoiseDetectorMA_M15
// @stars
// @info 
// @TODO 
int PSTrendDetector::Low1MA8_M15()
{
	const int tf = _periodMinus2;
	const int maPeriod = 8;
	int currentBar = iBars(_symbol, tf);

	if (currentBar != _lowMA_M15Data.LastBarNumber) 
	{
		_lowMA_M15Data.LastBarNumber = currentBar;
		// Get trend
		double ma1 = NormalizeDouble(iMA(_symbol, tf, maPeriod, 0 /*ma_shift*/, MODE_LWMA, PRICE_WEIGHTED, 1), _digits);
		double ma2 = NormalizeDouble(iMA(_symbol, tf, maPeriod, 0 /*ma_shift*/, MODE_LWMA, PRICE_WEIGHTED, 2), _digits);

		_lowMA_M15Data.CurrentTrend = DetectTrend(ma1, ma2);
	}

	return _lowMA_M15Data.CurrentTrend;
}

// @brief Noise detector with JFatl indicator. It works on M5. Old NoiseDetectorJFatlM5
// @stars
// @info 
// @TODO 
int PSTrendDetector::Low1JFatl_M5()
{
	const int tf = PERIOD_M5;
	const int length = 4;  
	const int phase = 100; //-100 ... +100, quality of process
	const int ipc = 0; /* Selecting prices, upon which the indicator will be calculated (0-CLOSE, 1-OPEN, 2-HIGH, 3-LOW, 4-MEDIAN, 5-TYPICAL, 6-WEIGHTED, 7-Heiken Ashi Close, 
		8-SIMPL, 9-TRENDFOLLOW, 10-0.5*TRENDFOLLOW, 11-Heiken Ashi Low, 12-Heiken Ashi High, 13-Heiken Ashi Open, 14-Heiken Ashi Close, 15-Heiken Ashi Open0.) */
	int currentBar = iBars(_symbol, tf);

	if (currentBar != _lowJFatlM5Data.LastBarNumber) 
	{
		_lowJFatlM5Data.LastBarNumber = currentBar;
		// Get trend
		double ma1 = NormalizeDouble(iCustom(_symbol, tf, IndicatorNameJFatl, length, phase, 0, ipc, 0, 1), _digits);
		double ma2 = NormalizeDouble(iCustom(_symbol, tf, IndicatorNameJFatl, length, phase, 0, ipc, 0, 2), _digits);

		_lowJFatlM5Data.CurrentTrend = DetectTrend(ma1, ma2);
	}

	return _lowJFatlM5Data.CurrentTrend;
}

int PSTrendDetector::Low1MA7LM()
{
	const int tf = _periodMinus1;
	const int maPeriod = 9;
	const int maMode = MODE_LWMA;
	const int maPrice = PRICE_CLOSE;
	
	int currentBar = iBars(_symbol, tf);

	if (currentBar != _lowMA_M30Data.LastBarNumber) 
	{
		_lowMA_M30Data.LastBarNumber = currentBar;
		
		double ma1 = iMA(_symbol, tf, maPeriod, 0, maMode, maPrice, 1);
		double ma2 = iMA(_symbol, tf, maPeriod, 0, maMode, maPrice, 2);

		_lowMA_M30Data.CurrentTrend = DetectTrend(ma1, ma2);
	}

	return _lowMA_M30Data.CurrentTrend;
}

// @brief It is my experiment. 
//			Expert 11 modified
// @stars
// @info Use MA H4 for big trend. Moving Average of Oscillator H1 for current trend and MA M15 for noise detection.
// @old xx signal
// @url: 
// @TODO 
int PSTrendDetector::Current1OsMA6_45_5()
{
	const int osmaFast = 6;
	const int osmaSlow = 45;
	const int osmaMACDSma = 5;
	
	double osma2 = iOsMA(_symbol, _period, osmaFast, osmaSlow, osmaMACDSma, PRICE_CLOSE, 2);
	double osma1 = iOsMA(_symbol, _period, osmaFast, osmaSlow, osmaMACDSma, PRICE_CLOSE, 1);

	if (osma2 < 0 && osma1 > 0)
	{
		return OP_BUY;
	}

	if (osma2 > 0 && osma1 < 0)
	{
		return OP_SELL;
	}

	return OP_NONE;
}

int PSTrendDetector::CurrentCloseMA7EC(int orderType)
{
	// TODO Importent! The noise filter should be calculated dipend a timeframe.
	if (orderType == OP_NONE) {
		return OP_NONE;
	}

	double spread = _market.GetSpreadPoints();

	const int maPeriod = 5;
	const int maMode = MODE_EMA;
	const int maPrice = PRICE_MEDIAN;
	// TODO Optimize.
	//const int maPrice = PRICE_CLOSE;
	//int maPrice = orderType == OP_BUY ? PRICE_CLOSE : PRICE_OPEN;

	double ma1 = NormalizeDouble(iMA(_symbol, _period, maPeriod, 0, maMode, maPrice, 1), _digits);
	double ma2 = NormalizeDouble(iMA(_symbol, _period, maPeriod, 0, maMode, maPrice, 2), _digits);

	double ma = ma1 - ma2;
	if (orderType == OP_BUY) 
	{
		// Init first.
		if (_currentCloseBuy == 0) {
			_currentCloseBuy = MathMax(ma1, ma2);
		}
				
		// Directon is OK, up.
		if (ma > 0) 
		{
			if (ma1 > _currentCloseBuy)	{
				_currentCloseBuy = ma1;
			}

			return OP_NONE;
		}
		
		// Checking for close.
		if (ma < 0) {
			// Checking noise
			double diff = _currentCloseBuy - ma1;

			// If diff (max price - current) > current spread - close position.
			if(diff > spread)
			{
				_currentCloseBuy = 0;

				return OP_BUY;
			}
		}
	}
	else //	if (orderType == OP_SELL) 
	{
		if (_currentCloseSell == 0) {
			_currentCloseSell = MathMin(ma1, ma2);
		}

		// Directon is OK, up.
		if (ma < 0) 
		{
			if (ma1 < _currentCloseSell)	{
				_currentCloseSell = ma1;
			}

			return OP_NONE;
		}
		
		// Checking for close.
		if (ma > 0) {
			// Checking noise
			double diff = ma1 - _currentCloseSell;
			// If diff (max price - current) > current spread - close position.
			if(diff > spread)
			{
				_currentCloseSell = 0;

				return OP_SELL;
			}
		}
	}

	// TODO Add check percent of max if trend is 0.01 % it isn't a problem. It is about 13 points.
	return OP_NONE;
}

// @brief Close order detector with MA5EC to detects trend and ATR14 for filter.
// @stars
// @info 
// @url: I use Exp_17.mq4 functionality.
// @TODO 
int PSTrendDetector::CurrentCloseMaAtrFlt(int orderType, double closeCoefficient /* 0.01 - 0.2 */)
{
	if (orderType == OP_NONE) {
		return OP_NONE;
	}

	const int maPeriod = 5;
	const int maMode = MODE_EMA;
	const int maPrice = PRICE_MEDIAN;
	const int atrPeriod = 14;
	const int atrPipsToPoint = 10;

	double ma1 = NormalizeDouble(iMA(_symbol, _period, maPeriod, 0, maMode, maPrice, 1), _digits);
	double ma2 = NormalizeDouble(iMA(_symbol, _period, maPeriod, 0, maMode, maPrice, 2), _digits);
	double atr1 = NormalizeDouble(iATR(_symbol, _period, atrPeriod, 1) /*  / atrPipsToPoint*/ * closeCoefficient, _digits);

	double ma = ma1 - ma2;
	if (orderType == OP_BUY) 
	{
		// Init first.
		if (_currentCloseBuy == 0) {
			_currentCloseBuy = MathMax(ma1, ma2);
		}
				
		// Directon is OK, up.
		if (ma > 0) 
		{
			if (ma1 > _currentCloseBuy)	{
				_currentCloseBuy = ma1;
			}

			return OP_NONE;
		}
		
		// Checking for close.
		if (ma < 0) {
			// Checking noise
			double diff = _currentCloseBuy - ma1;

			// If diff (max price - current) > current atr1 - close position.
			if(diff > atr1)
			{
				_currentCloseBuy = 0;

				return OP_BUY;
			}
		}
	}
	else //	if (orderType == OP_SELL) 
	{
		if (_currentCloseSell == 0) {
			_currentCloseSell = MathMin(ma1, ma2);
		}

		// Directon is OK, up.
		if (ma < 0) 
		{
			if (ma1 < _currentCloseSell) {
				_currentCloseSell = ma1;
			}

			return OP_NONE;
		}
		
		// Checking for close.
		if (ma > 0) {
			// Checking noise
			double diff = ma1 - _currentCloseSell;
			// If diff (max price - current) > current atr1 - close position.
			if(diff > atr1)
			{
				_currentCloseSell = 0;

				return OP_SELL;
			}
		}
	}

	// TODO Add check percent of max if trend is 0.01 % it isn't a problem. It is about 13 points.
	return OP_NONE;
}


int PSTrendDetector::CurrentCloseJfatl(int orderType)
{
	int result = OP_NONE;

	int signal = CurrentJtatl4();
	if (signal == OP_NONE) {
		return OP_NONE;
	}
	
	// Check if signal reversed.
	if (signal != orderType) {
		return orderType;
	}
	
	return OP_NONE;
}

void PSTrendDetector::ResetCloseValues(int orderType)
{
	if (orderType == OP_BUY) {
		_currentCloseBuy = 0;
	}
	
	if (orderType == OP_SELL) {
		_currentCloseSell = 0;
	}
}