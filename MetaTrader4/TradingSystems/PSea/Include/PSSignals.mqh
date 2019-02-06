//+------------------------------------------------------------------+
//|                                                    PSSignals.mqh |
//|                                   Copyright 2019, PSInvest Corp. |
//|                                          https://www.psinvest.eu |
//+------------------------------------------------------------------+
// Signals functions
// Necessary add indicator laguerre.mq4
#property copyright "Copyright 2019, PSInvest Corp."
#property link      "https://www.psinvest.eu"
#property version   "2.00"
#property strict
#include <FileLog.mqh>
#include <PSMarket.mqh>

class PSSignals
{
	public:
		PSSignals(CFileLog *fileLog, string symbol, int period);
		~PSSignals();
		bool CheckSignalIdIsValid(int signalId);
		int Signal(int signalId, bool isEintry);
	private:
		CFileLog *_fileLog;
		string _symbol;
		int _period;
		int _periodPlus1;
		int _period_1;
		int _digits;
		bool _isBought;
		bool _isSold;
		int _signalId;
		int Ship(bool isEntry);
		int MA3(bool isEntry);
		int CspLine(bool isEntry);
		int Collaps(bool isEntry);
		int Vegas1H(bool isEntry);
		int Envelop(bool isEntry);
		int Wpr2(bool isEntry);
		int Wpr(bool isEntry);
		int MA2(bool isEntry);
		int Macd(bool isEntry);
		int Sidus(bool isEntry);
		int SidusSafe(bool isEntry);
		int DifMA(bool isEntry);
		int ZigZag(bool isEntry);
		int InsideBar(bool isEntry);
		int BUOVB_BEOVB(bool isEntry);
		int T1Signal(bool isEntry, int fastMAPeriod, int slowMAPeriod);
		int T2Signal(bool isEntry, int periodCCI, int levelCCI);
		int T4Signal(bool isEntry, int currentCandle = 0);

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
		int ASCT_RAVI(bool isEntry);
		int HLHBTrendCatcher(bool isEntry, bool checkADX, bool checkMACD);
};

PSSignals::PSSignals(CFileLog *fileLog, string symbol, int period)
{
	_fileLog = fileLog;
	_symbol = symbol;
	_period = period;
	_digits = Digits;

	if (_period > PERIOD_D1) {
		_fileLog.Error(StringConcatenate("PSSignals::PSSignals. Period shouldn't greater than PERIOD_D1. Current:", period));
	}

	_isBought = false;
	_isSold = false;
	_periodPlus1 = GetNextTimeFrame(_period, 1);
	_period_1 = GetPreviousTimeFrame(_period, 1);
}

PSSignals::~PSSignals()
{

}

bool PSSignals::CheckSignalIdIsValid(int signalId)
{
	// TODO: uncomment after develop.
	//return signalId >= 1 && signalId <= 24;
	return true;
}

int PSSignals::Signal(int signalId, bool isEntry)
{
	_signalId = signalId;

	switch (signalId)
	{
		case 1: return Collaps(isEntry);
		case 2: return CspLine(isEntry);
		case 3: return DifMA(isEntry);
		case 4: return Envelop(isEntry);
		case 5: return Ship(isEntry);
		case 6: return Macd(isEntry);
		case 7: return MA2(isEntry);
		case 8: return MA3(isEntry);
		case 9: return Sidus(isEntry);
		case 10: return SidusSafe(isEntry);
		case 11: return Vegas1H(isEntry);
		case 12: return Wpr(isEntry);
		case 13: return Wpr2(isEntry);
		// New
		case 14: return ZigZag(isEntry);
		case 15: return InsideBar(isEntry);
		case 16: return BUOVB_BEOVB(isEntry);
		case 17: return T1Signal(isEntry, 10, 100);
		case 18: return T1Signal(isEntry, 30, 200);
		case 19: return T2Signal(isEntry, 30, 200);
		case 20: return T2Signal(isEntry, 90, 100);
		case 21: return T4Signal(isEntry);
		case 22: return ASCT_RAVI(isEntry);
		case 23: return HLHBTrendCatcher(isEntry, false, false);
		case 24: return HLHBTrendCatcher(isEntry, true, false);
		case 25: return HLHBTrendCatcher(isEntry, false, true);
		case 26: return HLHBTrendCatcher(isEntry, true, true);
	default: 
		{
		   _fileLog.Error(StringConcatenate(__FUNCTION__, " Invalid signal Id: ", signalId));
		   return -1;
		}
	}
}

// @brief
// @stars ***
// @info It is for good trend
// @old V1 3 signal
// TODO Refactoring
int PSSignals::Collaps(bool isEntry)
{
	int maPeriod=120;

	double laguerre = iCustom(_symbol, _period, "laguerre", 0.7, 100, 0, 1);
	double cci = iCCI(_symbol, _period, 14, PRICE_CLOSE, 0);
	double MA0 = iMA(_symbol, _period, maPeriod, 0, MODE_EMA, PRICE_MEDIAN, 0);
	double MA1 = iMA(_symbol, _period, maPeriod, 0, MODE_EMA, PRICE_MEDIAN, 1);

	if (isEntry)   //для открытия
	{ 	
		if (laguerre==0 && MA0>MA1 && cci<-10) 
			return (OP_BUY);

		if (laguerre==1 && MA0<MA1 && cci>10) 
			return (OP_SELL);
	}	
	else
	{
		if (laguerre>0.9) 
			return (OP_BUY);

		if (laguerre<0.1) 
			return (OP_SELL);
	}

	return -1;
}

// @brief
// @stars ***
// @info It is for orders without SL and Hedge orders.
// @old V1 4 signal
// TODO Refactoring
int PSSignals::CspLine(bool isEntry)
{
	int i;
	datetime time;
	double dp=0.0, mid=0.0, atr=0.0;
	double buy, sell;
	if (TimeHour(TimeCurrent())<7) 
	{ _isBought = false; _isSold = false;}

	if (TimeHour(TimeCurrent())>7 && (!_isBought || !_isSold))
	{
		time = StrToTime("7:00");
		i = iBarShift(_symbol, _period, time);
		atr = iATR(_symbol, _period, 15, i);
		dp = MathAbs(Open[i]-Close[i]);
		mid = (Open[i]+Close[i])/2;
		if (dp>50)	{ buy = Close[i]+atr; sell = Close[i]-atr;}
		else { buy = mid+atr; sell= mid-atr; }

		if (isEntry)   //для открытия
		{ 	
			if (Ask>buy && !_isBought) {_isBought = true; return (OP_BUY);}
 			if (Bid<sell && !_isSold) {_isSold = true; return (OP_SELL);}
		}	
		else
		{
			if (Ask>buy) return (OP_SELL);
 			if (Bid<sell) return (OP_BUY);
 		}
	}
   return -1; //нет сигнала
}

// @brief
// @stars **
// @info It is for counter trend + Hedge
// @old V1 5 signal
// TODO Refactoring
int PSSignals::DifMA(bool isEntry)
{
	//параметры средних 
	int MA5=5;
	int MA7=7;
	int MA25=25;
	int MA27=27;
	int MA55=55;
	int MA57=57;
	int MODE_MA=MODE_EMA;
	int PRICE=PRICE_MEDIAN;

   double dxCurA, dxPreA, dxCurB, dxPreB, dxCurC, dxPreC;
	double dx2, dx1, x, x0, x1, xx1, xx2;
	x = iMA(_symbol, _period, MA5, 0, MODE_MA, PRICE, 0);	
	x0 = iMA(_symbol, _period, MA5, 0, MODE_MA, PRICE, 1); 
	dx1 = x-x0; 
	xx1 = x0;
	
	x = iMA(_symbol, _period, MA7, 0, MODE_MA, PRICE, 0);	
	x0 = iMA(_symbol, _period, MA7, 0, MODE_MA, PRICE, 1); 
	dx2 = x-x0; 
	xx2 = x0;
	dxCurA = 100*(dx1-dx2);

	x1 = iMA(_symbol, _period, MA5, 0, MODE_MA, PRICE, 2); 
	dx1 = xx1-x1;
	
	x1 = iMA(_symbol, _period, MA7, 0, MODE_MA, PRICE, 2); 
	dx2 = xx2-x1;
	dxPreA = 100*(dx1-dx2);

	x = iMA(_symbol, _period, MA25, 0, MODE_MA, PRICE, 0);	
	x0 = iMA(_symbol, _period, MA25, 0, MODE_MA, PRICE, 1); 
	dx1 = x-x0; 
	xx1 = x0;
	
	x = iMA(_symbol, _period, MA27, 0, MODE_MA, PRICE, 0);	
	x0 = iMA(_symbol, _period, MA27, 0, MODE_MA, PRICE, 1); 
	dx2 = x-x0; 
	xx2 = x0;
	dxCurB = 100*(dx1-dx2);
	
	x1 = iMA(_symbol, _period, MA25, 0, MODE_MA, PRICE, 2); 
	dx1 = xx1-x1;
	x1 = iMA(_symbol, _period, MA27, 0, MODE_MA, PRICE, 2); 
	dx2 = xx2-x1;
	dxPreB = 100*(dx1-dx2);

	x = iMA(_symbol, _period, MA55, 0, MODE_MA, PRICE, 0);	
	x0 = iMA(_symbol, _period, MA55, 0, MODE_MA, PRICE, 1); 
	dx1 = x-x0; 
	xx1 = x0;
	
	x = iMA(_symbol, _period, MA57, 0, MODE_MA, PRICE, 0);	
	x0 = iMA(_symbol, _period, MA57, 0, MODE_MA, PRICE, 1); 
	dx2 = x-x0; 
	xx2 = x0;
	dxCurC = 100*(dx1-dx2);
	
	x1 = iMA(_symbol, _period, MA55, 0, MODE_MA, PRICE, 2); 
	dx1 = xx1-x1;
	x1 = iMA(_symbol, _period, MA57, 0, MODE_MA, PRICE, 2); 
	dx2 = xx2-x1;
	dxPreC = 100*(dx1-dx2);

	//----- условия для совершения операции
	if (isEntry)   //для открытия
	{
		if ((dxCurA>dxPreA) && (dxCurB>dxPreB) && (dxCurC>dxPreC))
			if (((dxCurB>0) && (dxPreB<0)) && ((dxCurC>0) && (dxPreC<0)))	return (OP_BUY);
		if ((dxCurA<dxPreA) && (dxCurB<dxPreB) && (dxCurC<dxPreC))
			if (((dxCurB<0) && (dxPreB>0)) && ((dxCurC<0) && (dxPreC>0)))	return (OP_SELL);
	}
	else //для закрытия
	{	
		if ((dxCurA>dxPreA) || (dxCurB>dxPreB) || (dxCurC>dxPreC))
			if (((dxCurB>0) && (dxPreB<0)) && ((dxCurC>0) && (dxPreC<0)))	return (OP_SELL);
		if ((dxCurA<dxPreA) || (dxCurB<dxPreB) || (dxCurC<dxPreC))
			if (((dxCurB<0) && (dxPreB>0)) && ((dxCurC<0) && (dxPreC>0)))	return (OP_BUY);
	}
 
   return -1; //нет сигнала
}

// @brief
// @stars ***
// @info It is can work for additional counter trend + Hedge
// @old V1 7 signal
// TODO Refactoring
int PSSignals::Envelop(bool isEntry)
{
	int slowMAPeriod=21;
	double Deviation=0.6;
	int Mode=MODE_SMA;//0-sma, 1-ema, 2-smma, 3-lwma
	int Price=PRICE_CLOSE;//0-close, 1-open, 2-high, 3-low, 4-median, 5-typic, 6-wieight
	
   double envH0, envL0, m0;
   double envH1, envL1, m1;
	envH0=iEnvelopes(_symbol, _period, slowMAPeriod, Mode, 0, Price, Deviation, MODE_UPPER, 0); 
	envH1=iEnvelopes(_symbol, _period, slowMAPeriod, Mode, 0, Price, Deviation, MODE_UPPER, 1); 

	envL0=iEnvelopes(_symbol, _period, slowMAPeriod, Mode, 0, Price, Deviation, MODE_LOWER, 0); 
	envL1=iEnvelopes(_symbol, _period, slowMAPeriod, Mode, 0, Price, Deviation, MODE_LOWER, 1); 

	m0 = (Low[0]+High[0])/2;	
	m1 = (Low[1]+High[1])/2;
	//----- условия для совершения операции
	if (isEntry)   //для открытия
	{ 	
		if (envH0<m0 && envH1<m1) return (OP_SELL);
		if (envL0>m0 && envL1>m1) return (OP_BUY);
	}
	else //для закрытия
	{
		if (envH0<m0 && envH1<m1) return (OP_BUY);
		if (envL0>m0 && envL1>m1) return (OP_SELL);
	}

   return -1; //нет сигнала
}

// @brief
// @stars ***
// @info It works only in strong trend.
// @old V1 9 signal
// TODO Refactoring
int PSSignals::Ship(bool isEntry)
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
	
	if (isEntry)   //для открытия
	{ 	
		if (ao0>ao1 && ac0>ac1 && Open[0]>=al1 && al1>al2 && al2>al3 && Low[0]>=sar && adxp>adxn) 
			return (OP_BUY);
		if (ao0<ao1 && ac0<ac1 && Open[0]<=al1 && al1<al2 && al2<al3 && High[0]<=sar && adxp<adxn) 
			return (OP_SELL);
	}	
	else
	{
		if (ao0>ao1 && ac0>ac1 && Open[0]>=al1 && al1>al2 && al2>al3 && Low[0]>=sar && adxp>adxn) 
			return (OP_SELL);
		if (ao0<ao1 && ac0<ac1 && Open[0]<=al1 && al1<al2 && al2<al3 && High[0]<=sar && adxp<adxn) 
			return (OP_BUY);
	}

	return -1;
}

// @brief
// @stars ****
// @info It works only in strong trend. It has good logics but sends and fake signals.
// @old V1 12 signal
// TODO Refactoring
int PSSignals::Macd(bool isEntry)
{
	double MACDOpen=3;
	double MACDClose=2;
	int maPeriod=26;
	int MODE_MA    = MODE_EMA; // метод вычисления средних
	int PRICE_MA   = PRICE_CLOSE; // метод вычисления средних

	//параметры средних
   double MacdCur, MacdPre, SignalCur;
   double SignalPre, MaCur, MaPre;

   MacdCur=iMACD(_symbol, _period, 8,17,9,PRICE_MA,MODE_MAIN,0);
   MacdPre=iMACD(_symbol, _period, 8,17,9,PRICE_MA,MODE_MAIN,1);

   SignalCur=iMACD(_symbol, _period, 8,17,9,PRICE_MA,MODE_SIGNAL,0);
   SignalPre=iMACD(_symbol, _period, 8,17,9,PRICE_MA,MODE_SIGNAL,1);

   MaCur=iMA(_symbol, _period, maPeriod,0,MODE_MA,PRICE_MA,0);
   MaPre=iMA(_symbol, _period, maPeriod,0,MODE_MA,PRICE_MA,1);

	//----- условия для совершения операции
	if (isEntry)   //для открытия
	{ 	
		if(MacdCur<0 && MacdCur>SignalCur && MacdPre<SignalPre 
			&& MathAbs(MacdCur)>(MACDOpen*Point) && MaCur>MaPre) 
				return (OP_BUY);
		if(MacdCur>0 && MacdCur<SignalCur && MacdPre>SignalPre 
			&& MacdCur>(MACDOpen*Point) && MaCur<MaPre) 
				return (OP_SELL);
	}
	else //для закрытия
	{	
      if(MacdCur>0 && MacdCur<SignalCur && MacdPre>SignalPre && MacdCur>(MACDClose*Point)) return (OP_BUY);
		if(MacdCur>0 && MacdCur<SignalCur && MacdPre>SignalPre && MacdCur>(MACDOpen*Point) && MaCur<MaPre) return (OP_BUY);

      if(MacdCur<0 && MacdCur>SignalCur && MacdPre<SignalPre && MathAbs(MacdCur)>(MACDClose*Point))  return (OP_SELL);
		if(MacdCur<0 && MacdCur>SignalCur && MacdPre<SignalPre && MathAbs(MacdCur)>(MACDOpen*Point) && MaCur>MaPre) return (OP_SELL);
	}
 
   return -1; //нет сигнала
}

// @brief
// @stars ***
// @info It would work with bigger SL and low profit.
// @old V1 15 signal
// TODO Refactoring
int PSSignals::MA2(bool isEntry)
{
	int PRICE   = PRICE_CLOSE; // метод вычисления средних
	int slowMAPeriod = 300;
	int fastMAPeriod = 30;	 
	double fMa1, fMa0, sMa1, sMa0, sar1, sar0;
	sMa1 = iMA(_symbol, _period, slowMAPeriod,0,MODE_SMA,PRICE,3);	
	sMa0 = iMA(_symbol, _period, slowMAPeriod,0,MODE_SMA,PRICE,0);
	fMa1 = iMA(_symbol, _period, fastMAPeriod,0,MODE_EMA,PRICE,3);	
	fMa0 = iMA(_symbol, _period, fastMAPeriod,0,MODE_EMA,PRICE,0);
	sar1 = iSAR(_symbol, _period, 0.02,0.2,6);	
	sar0 = iSAR(_symbol, _period, 0.02,0.2,0);

	if (isEntry)   //для открытия
	{ 	
   	if ((sMa1>fMa1*0.998 && sMa0<fMa0*0.998)&& sar1>Open[6]&&sar0<Open[0]) 
			return (OP_BUY);
   	
		if ((sMa1<fMa1*0.998 && sMa0>fMa0*0.998)&& sar1<Open[6]&&sar0>Open[0]) 
			return (OP_SELL);
   }
   else
	{
		if (sMa1<fMa1*0.998 && sMa0>fMa0*0.9978) 
			return (OP_BUY);

      if (sMa1>fMa1*0.998 && sMa0<fMa0*0.9978) 
			return (OP_SELL);
   }
   
	return -1; //нет сигнала
}

// @brief
// @stars ****
// @info It looks good necessary more tests.
// @old V1 16 signal
// TODO Refactoring
int PSSignals::MA3(bool isEntry)
{
	int nextPeriod = GetNextTimeFrame(_period);
	if (nextPeriod == -1) {
	   _fileLog.Error(StringConcatenate("PSSignals. Invalid next Time frame. Signal Id: ", _signalId));
		return -1;
	}
	
	int w4 = 4, w8=8, d5=5, d20=20;
	double w4_0, w4_1, w8_0, w8_1, d5_0, d5_1, d5_2, d20_0, d20_1;
	//w4_0 = iMA(NULL, PERIOD_W1, w4, 0, MODE_SMA, PRICE_CLOSE, 0);
	w4_0 = iMA(_symbol, nextPeriod, w4, 0, MODE_SMA, PRICE_CLOSE, 0);
	w4_1 = iMA(_symbol, nextPeriod, w4, 0, MODE_SMA, PRICE_CLOSE, 1);
	w8_0 = iMA(_symbol, nextPeriod, w8, 0, MODE_SMA, PRICE_CLOSE, 0);
	w8_1 = iMA(_symbol, nextPeriod, w8, 0, MODE_SMA, PRICE_CLOSE, 1);
	
	// 	d5_0 = iMA(NULL, PERIOD_D1, d5, 0, MODE_SMA, PRICE_CLOSE, 0);
	d5_0 = iMA(_symbol, _period, d5, 0, MODE_SMA, PRICE_CLOSE, 0);
	d5_1 = iMA(_symbol, _period, d5, 0, MODE_SMA, PRICE_CLOSE, 1);
	d5_2 = iMA(_symbol, _period, d5, 0, MODE_SMA, PRICE_CLOSE, 2);
	d20_0 = iMA(_symbol, _period, d20, 0, MODE_SMA, PRICE_CLOSE, 0);
	d20_1 = iMA(_symbol, _period, d20, 0, MODE_SMA, PRICE_CLOSE, 1);
	
	if (isEntry)   //для открытия
	{ 	
		if (w4_0>w4_1 && w8_0>w8_1 && d20_0>d20_1 && d5_0>d5_1 && d5_2>d5_1) 
			return (OP_BUY);
		
		if (w4_0<w4_1 && w8_0<w8_1 && d20_0<d20_1 && d5_0<d5_1 && d5_2<d5_1) 
			return (OP_SELL);
	}	
	else
	{
		if (w4_0>w4_1 && w8_0>w8_1 && d20_0>d20_1 && d5_0>d5_1 && d5_2>d5_1) 
			return (OP_SELL);
		
		if (w4_0<w4_1 && w8_0<w8_1 && d20_0<d20_1 && d5_0<d5_1 && d5_2<d5_1) 
			return (OP_BUY);
	}
   
	return -1; //нет сигнала
}

// @brief
// @stars ****
// @info It only in strong trend.
// @old V1 17 signal
// TODO Refactoring
int PSSignals::Sidus(bool isEntry)
{
	//параметры средних
	int MABluFast  = 5; // синий
	int MABluSlow  = 8; //  канал 
	int MARedFast  = 16; // красный
	int MARedSlow  = 28; //  канал 
	int MODE_MA    = MODE_EMA; // метод вычисления средних
	int PRICE_MA   = PRICE_CLOSE; // метод вычисления средних

   double rf, rs, bf, bs;
   bf=iMA(_symbol, _period, MABluFast, 0, MODE_MA, PRICE_MA, 0);
   bs=iMA(_symbol, _period, MABluSlow, 0, MODE_MA, PRICE_MA, 0);

   rf=iMA(_symbol, _period, MARedFast, 0, MODE_MA, PRICE_MA, 0);
   rs=iMA(_symbol, _period, MARedSlow, 0, MODE_MA, PRICE_MA, 0);

	//----- условия для совершения операции
	if (isEntry)   //для открытия
	{ 	
		if ((rf>rs) && (bf>bs) && (Ask<=bs))  return (OP_BUY);   
		if ((rf<rs) && (bf<bs) && (Bid>=bs))  return (OP_SELL); 
	}
	else //для закрытия
	{	
		if ((bf<bs) && (bs<rf))  return (OP_BUY); 
		if ((bf>bs) && (bs>rf))  return (OP_SELL);  
	}
 
   return -1; //нет сигнала
}

// @brief
// @stars ****
// @info It only in strong trend, it is better than Sidus.
// @old V1 18 signal
// TODO Refactoring
int PSSignals::SidusSafe(bool isEntry)
{
	//параметры средних сидуса
	int MABluFast  = 5; // синий
	int MABluSlow  = 8; //  канал 
	int MARedFast  = 16; // красный
	int MARedSlow  = 28; //  канал 
	int MODE_MA    = MODE_EMA; // метод вычисления средних
	int PRICE_MA   = PRICE_CLOSE; // метод вычисления средних

	//параметры RVI
	int RVI_PERIOD  = 100; 

	//параметры Stoch
	int K_PERIOD		= 8; 
	int D_PERIOD		= 5; 
	int SLOW				= 5; 
	int METHOD_STOCH	= MODE_EMA; // метод вычисления средних

   double rf, rs, bf, bs, rvi, rvi_signal, stoch;
   bf=iMA(_symbol, _period, MABluFast, 0, MODE_MA, PRICE_MA, 0);
   bs=iMA(_symbol, _period, MABluSlow, 0, MODE_MA, PRICE_MA, 0);

   rf=iMA(_symbol, _period, MARedFast, 0, MODE_MA, PRICE_MA, 0);
   rs=iMA(_symbol, _period, MARedSlow, 0, MODE_MA, PRICE_MA, 0);
   
   rvi = iRVI(_symbol, _period, RVI_PERIOD, MODE_MAIN, 0);
   rvi_signal = iRVI(_symbol, _period, RVI_PERIOD, MODE_SIGNAL, 0);
	
	stoch = iStochastic(_symbol, _period, K_PERIOD, D_PERIOD, SLOW, METHOD_STOCH, 0, MODE_MAIN, 0);
	//----- условия для совершения операции
	if (isEntry)   //для открытия
	{ 	
		if ((rf>rs) && (bf>bs) && (Ask<=bs) && (rvi>=rvi_signal) && (stoch>50))  return (OP_BUY);   
		if ((rf<rs) && (bf<bs) && (Bid>=bs) && (rvi<=rvi_signal) && (stoch<50))  return (OP_SELL); 
	}
	else //для закрытия
	{	
		if ((bf<bs) && (bs<rf))  return (OP_BUY); 
		if ((bf>bs) && (bs>rf))  return (OP_SELL);  
	}
 
   return -1; //нет сигнала
}

// @brief
// @stars 
// @info It hasn't work yet.
// @old V1 20 signal
// TODO Refactoring
int PSSignals::Vegas1H(bool isEntry)
{
	int slowMAPeriod=169;
	double Deviation=0.04;
	int Mode=MODE_EMA;//0-sma, 1-ema, 2-smma, 3-lwma
	int Price=PRICE_CLOSE;//0-close, 1-open, 2-high, 3-low, 4-median, 5-typic, 6-wieight

   double envH, envL;
	envH=iEnvelopes(_symbol, _period, slowMAPeriod, Mode, 0, Price, Deviation, MODE_UPPER, 0); 
	envL=iEnvelopes(_symbol, _period, slowMAPeriod, Mode, 0, Price, Deviation, MODE_LOWER, 0); 
	
	int signal = -1; //нет сигнала
	
	if (isEntry)   //для открытия
	{ 	
		if (Bid<envL && High[0]>envH) return (OP_SELL);
		if (Bid>envH && Low[0]<envL) return (OP_BUY);
	}
	else //для закрытия
	{
		if (Bid<envL && High[0]>envH) return (OP_BUY);
		if (Bid>envH && Low[0]<envL) return (OP_SELL);
	}
	
   return (signal);
}

// @brief
// @stars ***
// @info It is slow. It has good enters. We can use it but necessary optimize it.
// @old V1 22 signal
// TODO Refactoring
int PSSignals::Wpr(bool isEntry)
{
	int    m=20;
   double wpr0, wpr1, wpr2;

	wpr0=iWPR(_symbol, _period, m, 0); 
	wpr1=iWPR(_symbol, _period, m, 1); 
	wpr2=iWPR(_symbol, _period, m, 2); 
		
	//----- условия для совершения операции
	if (isEntry)   //для открытия
	{ 	
		if (wpr2> -80 && wpr1< -80 && wpr0>-80) return (OP_BUY);
		if (wpr2< -20 && wpr1> -20 && wpr0<-20) return (OP_SELL);
	}
	else //для закрытия
	{
		if (wpr2> -80 && wpr1< -80 && wpr0>-80) return (OP_SELL);
		if (wpr2< -20 && wpr1> -20 && wpr0<-20) return (OP_BUY);
	}	
   
	return -1; //нет сигнала
}

// @brief
// @stars ****
// @info It is good. We can use it with Hedge.
// @old V1 23 signal
// TODO Refactoring
int PSSignals::Wpr2(bool isEntry)
{
   int i;
   double wpr0, wpr1;
   int val, period=9;
   double Range;
   int M1=-1,M2=-1;
	bool b;	
   //******************************************************************************
 	Range=0.0;
	for (i=0; i<=period; i++) Range=Range+MathAbs(High[i]-Low[i]);
	Range=Range/(period+1);

	b=false; i=0;
	while (i<period && !b)
	{ 
		if (MathAbs(Open[i]-Close[i+1])>=Range*2.0) {
			b = true; 
		}
		
		i++; 
	}
	if (b) {
		val=(int)MathFloor(period/3);
	}

	b=false; 
	i=0;
	while (i<period-3 && !b)
	{ 
		if (MathAbs(Close[i+3]-Close[i])>=Range*4.6) { 
			b = true; 
		}
	
		i++;	
	}
	
	if (b) 
		val=(int)MathFloor(period/2); 
	else 
		val=period;

	
	wpr0=100-MathAbs(iWPR(_symbol, _period, val,0)); wpr1=100-MathAbs(iWPR(_symbol, _period, val,1));
   
	if (isEntry)   //для открытия
	{ 	
      if (wpr0>80 && wpr1<80) 
			return (OP_BUY);
      
		if (wpr0<20 && wpr1>20) 
			return (OP_SELL);
	}
	else //для закрытия
	{
      if (wpr0<20) 
			return (OP_BUY);

      if (wpr0>80) 
			return (OP_SELL);
	}
   
	return -1; //нет сигнала
}

// @brief Signal from ZigZag Indicator
// @stars 
// @info First signal after pick is true.
// @old V2 14 signal
// @TODO it is necessary filter fake signals. Perhaps we may develop this indicator + another one.
int PSSignals::ZigZag(bool isEntry)
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
					return -1;

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

	if (firstPeak < secondPeak)	
		return isEntry ? OP_BUY : OP_SELL;

	if (firstPeak > secondPeak)	
		return isEntry ? OP_SELL : OP_BUY;

	return -1;
}

// @brief InsideBar signal. D1 only. It should open 2 stop BS orders.
// @stars
// @info 
// @old V2 15 signal
// @url: https://www.mql5.com/en/articles/1771
// @TODO 
int PSSignals::InsideBar(bool isEntry)
{
	double   open1,//first candle Open price
		open2,    //second candle Open price
		close1,   //first candle Close price
		close2,   //second candle Close price
		low1,     //first candle Low price
		low2,     //second candle Low price
		high1,    //first candle High price
		high2;    //second candle High price
	int     bar2size          = 800;
	open1        = NormalizeDouble(iOpen(_symbol, _period, 1), _digits);
	open2        = NormalizeDouble(iOpen(_symbol, _period, 2), _digits);
	close1       = NormalizeDouble(iClose(_symbol, _period, 1), _digits);
	close2       = NormalizeDouble(iClose(_symbol, _period, 2), _digits);
	low1         = NormalizeDouble(iLow(_symbol, _period, 1), _digits);
	low2         = NormalizeDouble(iLow(_symbol, _period, 2), _digits);
	high1        = NormalizeDouble(iHigh(_symbol, _period, 1), _digits);
	high2        = NormalizeDouble(iHigh(_symbol, _period, 2), _digits);

	double _bar2size=NormalizeDouble(((high2-low2)/Point),0);

	// if the second bar is bearish, while the first one is bullish
	if(//timeBarInside!=iTime(_symbol,_period,1) && //no orders have been opened at this pattern yet
		_bar2size>bar2size && //the second bar is big enough, so the market is not flat
		open2>close2 && //the second bar is bullish
		close1>open1 && //the first bar is bearish
		high2>high1 &&  //the bar 2 High exceeds the first one's High
		open2>close1 && //the second bar's Open exceeds the first one's Close
		low2<low1)      //the second bar's Low is lower than the first one's Low
	{
		return isEntry ? OP_BUY : OP_SELL;
	}

	// if (firstPeak > secondPeak)	
	// 	return isEntry ? OP_SELL : OP_BUY;

	return -1;
}

// @brief BUOVB_BEOVB signal. D1 only. It should open 2 stop BS orders.
// @stars
// @info BUOVB — Bullish Outside Vertical Bar, BEOVB — Bearish Outside Vertical Bar.
// @old V2 16 signal
// @url: https://www.mql5.com/en/articles/1946
// @TODO 
int PSSignals::BUOVB_BEOVB(bool isEntry)
{
	int     interval          = 25;                               //Interval
	int     bar1size          = 900;                              //Bar 1 Size

	double   open1,//first candle Open price
		open2,    //second candle Open price
		close1,   //first candle Close price
		close2,   //second candle Close price
		low1,     //first candle Low price
		low2,     //second candle Low price
		high1,    //first candle High price
		high2;    //second candle High price

	// define prices of necessary bars
	open1        = NormalizeDouble(iOpen(_symbol, _period, 1), _digits);
	open2        = NormalizeDouble(iOpen(_symbol, _period, 2), _digits);
	close1       = NormalizeDouble(iClose(_symbol, _period, 1), _digits);
	close2       = NormalizeDouble(iClose(_symbol, _period, 2), _digits);
	low1         = NormalizeDouble(iLow(_symbol, _period, 1), _digits);
	low2         = NormalizeDouble(iLow(_symbol, _period, 2), _digits);
	high1        = NormalizeDouble(iHigh(_symbol, _period, 1), _digits);
	high2        = NormalizeDouble(iHigh(_symbol, _period, 2), _digits);

	double _bar1size=NormalizeDouble(((high1-low1)/Point),0);
	// Finding bearish pattern BEOVB
	if(//timeBUOVB_BEOVB!=iTime(_symbol,_period,1) && // orders are not yet opened for this pattern 
			_bar1size>bar1size && //first bar is big enough not to consider a flat market
			low1 < low2 &&        //First bar's Low is below second bar's Low
			high1 > high2 &&      //First bar's High is above second bar's High
			close1 < open2 &&     //First bar's Close price is lower than second bar's Open price
			open1 > close1 &&     //First bar is a bearish bar
			open2 < close2)       //Second bar is a bullish bar
	{
		// we have described all conditions indicating that the first bar completely engulfs the second bar and is a bearish bar
		return isEntry ? OP_SELL : OP_BUY;
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
		return isEntry ? OP_BUY : OP_SELL;
	}

	return -1;
}

// @brief EMA.
// @stars
// @info 
// @old V2 17, 18 signal
// @url: https://www.mql5.com/en/articles/1578
// @TODO 
int PSSignals::T1Signal(bool isEntry, int fastMAPeriod, int slowMAPeriod)
{
	double MA_Fast     =iMA(_symbol, _period, fastMAPeriod, 0, MODE_EMA, PRICE_CLOSE, 1);
	double MA_Fast_Last=iMA(_symbol, _period, fastMAPeriod, 0, MODE_EMA, PRICE_CLOSE, 2);
	double MA_Slow     =iMA(_symbol, _period, slowMAPeriod, 0, MODE_EMA, PRICE_CLOSE, 1);
	double MA_Slow_Last=iMA(_symbol, _period, slowMAPeriod, 0, MODE_EMA, PRICE_CLOSE, 2);

	if(isEntry)
	{
		if(MA_Slow > MA_Slow_Last)
		{
			if(MA_Fast > MA_Slow && MA_Fast_Last < MA_Slow_Last)
			{
				return(OP_BUY);
			}
		}
		if(MA_Slow < MA_Slow_Last)
		{
			if(MA_Fast < MA_Slow && MA_Fast_Last > MA_Slow_Last)
			{
				return(OP_SELL);
			}
		}
	}
	else
	{
		if(MA_Fast < MA_Slow) 
			return OP_BUY;
		
		if(MA_Fast > MA_Slow) 
			return OP_SELL;
	}

	return -1;
}

// @brief CCI.
// @stars
// @info 
// @old V2 19, 20 signal
// @url: https://www.mql5.com/en/articles/1578
// @TODO 
int PSSignals::T2Signal(bool isEntry, int periodCCI, int levelCCI)
{
	double CCI = iCCI(_symbol, _period, periodCCI, PRICE_TYPICAL, 1);
	double CCILast = iCCI(_symbol, _period, periodCCI, PRICE_TYPICAL, 2);

	if(CCI < levelCCI && CCILast > levelCCI) 
		return isEntry ? OP_SELL : OP_BUY;

	if( (CCI > -levelCCI) && (CCILast < -levelCCI)) 
		return isEntry ? OP_BUY : OP_SELL;
	
	return -1;
}

// @brief 
// @stars
// @info 
// @old V2 21 signal
// @url: https://www.mql5.com/en/articles/1578
// @TODO 
int PSSignals::T4Signal(bool isEntry, int currentCandle = 0)
{
	double T4_LimitMACD = 0.002;

	if(isEntry)
	{
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
	}
	else // Exit
	{
		double MA50 = iMA(NULL,0,50 ,0,MODE_EMA,PRICE_OPEN,0);

		if(Close[1]<MA50)
		{
			return OP_BUY;
		}

		if(Close[1]>MA50) 
		{
			return OP_SELL;
	   }
	}   
	
	return -1;
}

bool PSSignals::Get_RAVI(int Number, string symbol,int timeframe, 
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

bool PSSignals::Get_ASCTrend1(int Number, string symbol,int timeframe, 
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
int PSSignals::ASCT_RAVI(bool isEntry)
{
	int RAVI_Timeframe = _period;
	int ASCT_Timeframe = _periodPlus1;
	int RISK_Up = 3;
	int RISK_Dn = 3;
	int Period1_Up = 7; 
	int Period2_Up = 65; 
	int Period1_Dn = 7; 
	int Period2_Dn = 65; 
	int MA_Metod_Up = 0; // 0 MODE_SMA, 1 MODE_EMA, 2 MODE_SMMA, 3 MODE_LWMA
	int PRICE_Up = 0; // 0 PRICE_CLOSE, 1 PRICE_OPEN, 2 PRICE_HIGH, 3 PRICE_LOW, 4 PRICE_MEDIAN, 5 PRICE_TYPICAL, 6 PRICE_WEIGHTED
	int MA_Metod_Dn = 0;
	int PRICE_Dn = 0;

	if(iBars(_symbol, ASCT_Timeframe) < 3 + RISK_Up*2 + 1 + 1)
		return -1;
	if(iBars(_symbol, ASCT_Timeframe) < 3 + RISK_Dn*2 + 1 + 1)
		return -1;

	if(iBars(_symbol, RAVI_Timeframe) < MathMax(Period1_Up, Period2_Up + 4))
		return -1;
	if (iBars(_symbol,RAVI_Timeframe)<MathMax(Period1_Dn,Period2_Dn+4))
		return -1;

	static int LastBars;
	int bar;

	if(LastBars != iBars(_symbol, RAVI_Timeframe))
	{
		Get_RAVI(0, _symbol, RAVI_Timeframe, false, Period1_Up, Period2_Up, MA_Metod_Up, PRICE_Up);
		for(bar = 3; bar >= 0; bar--)
			RAVI_Up[bar] = RAVI_Buffer[0][bar];

		Get_ASCTrend1(0, _symbol, ASCT_Timeframe, false, RISK_Up);
			ASCTrend1_Up[1] = ASCTrend1_Buffer[0][1];  

		Get_RAVI(1, _symbol, RAVI_Timeframe, false, Period1_Dn, 
			Period2_Dn, MA_Metod_Dn, PRICE_Dn);
		for(bar = 3; bar >= 0; bar--)
			RAVI_Dn[bar] = RAVI_Buffer[1][bar];

		Get_ASCTrend1(1, _symbol, ASCT_Timeframe, false, RISK_Dn); 
			ASCTrend1_Dn[1] = ASCTrend1_Buffer[1][1]; 
	}

	LastBars = iBars(_symbol, RAVI_Timeframe);
	if(RAVI_Up[2] - RAVI_Up[3] < 0)
		if(RAVI_Up[1] - RAVI_Up[2] > 0)
			if(ASCTrend1_Up[1] > 0)
				return isEntry ? OP_BUY : OP_SELL;

	if(RAVI_Dn[2] - RAVI_Dn[3] > 0)
		if(RAVI_Dn[1] - RAVI_Dn[2] < 0)
			if(ASCTrend1_Dn[1] < 0)
				return isEntry ? OP_SELL : OP_BUY;

	return -1;
}

// @brief HLHB Forex Trend-Catcher System
// @stars
// @info 
// @old V2 23 signal
// @url: https://www.babypips.com/trading/forex-hlhb-system-explained
// @TODO 
int PSSignals::HLHBTrendCatcher(bool isEntry, bool checkADX, bool checkMACD)
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
		
		if (adx1 <= 25)
			return -1;
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
				return -1;
			}
			return isEntry ? OP_BUY : OP_SELL;
		}
	}

	if((maFast2 > maSlow2 ||  maFast2 == maSlow2)
		&& (maFast1 < maSlow1 || maFast1 == maSlow1))
	{
		if (rsi2 >= rsiCentre && rsi1 <= rsiCentre && rsi2 > rsi1)
		{
			if(checkMACD && !(macd2 > 0 && macd1 < 0))
			{
				return -1;
			}
			return isEntry ? OP_SELL : OP_BUY;
		}
	}

	return -1;
}