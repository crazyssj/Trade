//+------------------------------------------------------------------+
//|                                                    PSSignals.mqh |
//|                                   Copyright 2019, PSInvest Corp. |
//|                                          https://www.psinvest.eu |
//+------------------------------------------------------------------+
// Signals functions
#property copyright "Copyright 2019, PSInvest Corp."
#property link      "https://www.psinvest.eu"
#property version   "1.00"
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
		bool _isBought;
		bool _isSold;
		int _signalId;
		int Korablik(bool isEntry);
		int Laguer(bool isEntry);
		int BorChan(bool isEntry);
		int ZigZag(bool isEntry);
		int MA3(bool isEntry);
		int CspLine(bool isEntry);
		int Collaps(bool isEntry);
		int Vegas1H(bool isEntry);
		int Envelop2(bool isEntry);
		int Envelop(bool isEntry);
		int Wpr2(bool isEntry);
		int Wpr(bool isEntry);
		int MA2(bool isEntry);
		int slowMAPeriod(bool isEntry);
		int Macd2(bool isEntry);
		int Macd(bool isEntry);
		int Sidus(bool isEntry);
		int SidusSafe(bool isEntry);
		int SidusSinc(bool isEntry);
		int BlackSys(bool isEntry);
		int Vegas4H(bool isEntry);
		int DifMA(bool isEntry);
		int DifMAS(bool isEntry);
		int CCI();
};

// PK
//#include <../Indicators/Laguerre.mq4>
// Install Laguerre.mq4 in /Indicators/Laguerre.mq4

PSSignals::PSSignals(CFileLog *fileLog, string symbol, int period)
{
	_fileLog = fileLog;
	_symbol = symbol;
	_period = period;

	if (_period > PERIOD_D1) {
		_fileLog.Error(StringConcatenate("PSSignals::PSSignals. Period shouldn't greater than PERIOD_D1. Current:", period));
	}

	_isBought = false;
	_isSold = false;
}

PSSignals::~PSSignals()
{

}

bool PSSignals::CheckSignalIdIsValid(int signalId)
{
	return signalId >= 1 && signalId <= 24;
}

int PSSignals::Signal(int signalId, bool isEntry)
{
	_signalId = signalId;

	switch (signalId)
	{
		// Do not use it.
		case 1:	return (BlackSys(isEntry)); break;
		// Do not use it.
		case 2:		return (BorChan(isEntry)); break;
		// Do not use it.
		case 3:		return (Collaps(isEntry)); break;
		// -91.82
		case 4:		return (CspLine(isEntry)); break;
		// -129.04
		case 5:			return (DifMA(isEntry)); break;
		// -20.52
		case 6:		return (DifMAS(isEntry)); break;
		// -6.92
		case 7:		return (Envelop(isEntry)); break;
		// -140.07
		case 8:	return (Envelop2(isEntry)); break;
		// -269.81
		case 9:	return (Korablik(isEntry)); break;
		// -680.47
		case 10:	return (ZigZag(isEntry)); break;
		// -91.17
		case 11:		return (Laguer(isEntry)); break;
		// 16.68
		case 12:			return (Macd(isEntry)); break;
		// 13.16
		case 13:			return (Macd2(isEntry)); break;
		// -236.64
		case 14:		return (slowMAPeriod(isEntry)); break;
		// 20.04
		case 15:	return (MA2(isEntry)); break;
		// -129.76
		case 16:	return (MA3(isEntry)); break;
		// -315.13
		case 17:			return (Sidus(isEntry)); break;
		// -65.94
		case 18:	return (SidusSafe(isEntry)); break;
		// -64.26
		case 19:	return (SidusSinc(isEntry)); break;
		// H1 55.64  H4 -125.89
		case 20:		return (Vegas1H(isEntry)); break;
		// H4 -175.61  H1 -69.54
		case 21:		return (Vegas4H(isEntry)); break;
		// H1 -76.58   H4 52.67
		case 22:				return (Wpr(isEntry)); break;
		// -445.50
		case 23:			return (Wpr2(isEntry)); break;
		// -26.66
		case 24: return CCI(); break;   
		//case 9:			return (Force(isEntry)); break;

		default: 
		{
		   _fileLog.Error(StringConcatenate("PSSignals::Signal Invalid signal Id: ", signalId));
		   return -1;
		}
	}
}

// PK
/*
int DayMA(bool isEntry)
{
	int i;
	datetime time;
	double dp=0.0;
	double buy, sell;
	double hi=0.0, lo=0.0, avg=0.0, op=0.0, cl=0.0;
	double do_=0.0, dc=0.0;
	if (TimeHour(TimeCurrent())<=20) 
	{ _isBought = false; _isSold = false; return -1;}
	
	if (TimeMinute(TimeCurrent())==21 && (!_isBought || !_isSold))
	{
		hi = iHigh(NULL, PERIOD_D1, 0); lo = iLow(NULL, PERIOD_D1, 0); avg = (hi+lo)/2;
		op = iOpen(NULL, PERIOD_D1, 0); cl = iClose(NULL, PERIOD_D1, 0);
		do_ = MathAbs(op-avg); dc = MathAbs(cl-avg); 
		
		time = StrToTime("7:00");
		i = iBarShift(_symbol, _period, time);

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
*/
int PSSignals::Korablik(bool isEntry)
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

int PSSignals::Laguer(bool isEntry)
{
	double L1, L2;
  
	L1=iCustom(_symbol, _period, "Laguerre", 0.7, 100, 0, 1);
	L2=iCustom(_symbol, _period, "Laguerre", 0.7, 100, 0, 2);
  
	if (isEntry)   //для открытия
	{ 	
		if (L1>L2 && L2==0) return (OP_BUY);
   	if (L1<L2 && L2==1) return (OP_SELL);
	}	
	else
	{
		if (L1>L2 && L2==0) return (OP_SELL);
   	if (L1<L2 && L2==1) return (OP_BUY);
	}
	return -1;
}

// Indicator is not found.
// int Force(bool isEntry)
// {
// 	double f1 = iCustom(_symbol, _period, "Sem Force", 10, 3, 50, MODE_SMA, PRICE_CLOSE, 3, 1);
// 	double f2 = iCustom(_symbol, _period, "Sem Force", 10, 3, 50, MODE_SMA, PRICE_CLOSE, 3, 2);
	
// 	if (isEntry) 
// 	{
// 		if (f1<f2 && f2==100) return (OP_SELL);// Если достигли верхней границы канала
// 		if (f1>f2 && f2==-100) return (OP_BUY);// Если достигли нижней границы канала
// 	}
// 	else
// 	{
// 		if (f1<f2 && f2==100) return (OP_BUY);// Если достигли верхней границы канала
// 		if (f1>f2 && f2==-100) return (OP_SELL);// Если достигли нижней границы канала
// 	}
// 	return -1;
// }

// Too late open position in a chanel. Sell signal is wrong.
// In down channel send buy signal??? In horizontal channel open position?
int PSSignals::BorChan(bool isEntry)
{
	//ObjectDelete("GC_Channel1"); ObjectDelete("GC_Channel2");
	int pos, pos2, Depth=12;
	int i=Depth;
	double h1 = 0.0, h2 = 0.0, l1 = 0.0, l2 = 0.0; 
	int xh1=0, xh2=0, xl1=0, xl2=0;
	double pl=0.0, ph=0.0;
	
	while(i<Bars-1 && xh1==0)
	{
		pos = iHighest(_symbol, _period, MODE_HIGH,2*Depth+1,i-Depth);	
		pos2 = iHighest(_symbol, _period, MODE_HIGH,2*Depth+1,pos-Depth); 
		
		if (pos==pos2 && pos>=Depth) 
		{ 
		   if (High[pos]==High[pos-1]) 
		      pos = pos-1; 
		   h1=High[pos];  
		   xh1=pos;
		}
		i++;
	}
	
	i = xh1+2*Depth;
	
	while(i<Bars-1 && xh2==0)
	{
		pos = iHighest(_symbol, _period, MODE_HIGH,2*Depth+1,i-Depth);	
		pos2 = iHighest(_symbol, _period, MODE_HIGH,2*Depth+1,pos-Depth); 
		
		if (pos==pos2 && pos>=Depth) 
		{ 
		   if (High[pos]==High[pos-1]) 
		      pos = pos-1; 
		   h2=High[pos];  
		   xh2=pos;
		}
		i++;
	}
	
	i = Depth;
   
	while(i<Bars-1 && xl1==0)
	{
   	pos = iLowest(_symbol, _period, MODE_LOW,2*Depth+1,i-Depth);	
		pos2 = iLowest(_symbol, _period, MODE_LOW,2*Depth+1,pos-Depth); 
		
		if (pos==pos2 && pos>=Depth) 
		{ 
		   if (Low[pos]==Low[pos-1]) 
		      pos = pos-1; 
		   l1=Low[pos]; 
		   xl1 = pos;
		}
   	i++;
	}
	
	i = xl1+2*Depth;
	
	while(i<Bars-1 && xl2==0)
	{
		pos = iLowest(_symbol, _period, MODE_LOW,2*Depth+1,i-Depth);	
		pos2 = iLowest(_symbol, _period, MODE_LOW,2*Depth+1,pos-Depth); 
		
		if (pos==pos2 && pos>=Depth) 
		{ 
		   if (Low[pos]==Low[pos-1]) 
		      pos = pos-1; 
		   l2=Low[pos]; 
		   xl2 = pos; 
		}
		i++;
	}
	
	//если сначала нашли низ
	if (xh1>xl1) 
	{ 
		h2=h1-(l1-l2); xh2 = xh1+(xl2-xl1); 
	} 
	else 
	{ 
		l2=l1-(h1-h2); xl2 = xl1+(xh2-xh1); 
	}
	
	pl = l2+xl2*(l1-l2)/(xl2-xl1); 
	ph = h2+xh2*(l1-l2)/(xl2-xl1);

   static int objId = 1;

//	double MA0=0.0, MA1=0.0;
//	MA0=iMA(_symbol, _period, 16,0,MODE_EMA,PRICE_CLOSE,0);	MA1=iMA(_symbol, _period, 28,0,MODE_EMA,PRICE_CLOSE,0);

	if (isEntry) 
	{
		if (Bid>=ph-2*Point && Bid<=ph+2*Point) 
		{
			ObjectCreate(StringConcatenate("GC_Channel1 ", objId++), OBJ_TREND, 0, Time[xh2], h2, Time[xh1], h1);
			ObjectCreate(StringConcatenate("GC_Channel2 ", objId++), OBJ_TREND, 0, Time[xl2], l2, Time[xl1], l1);
		  return (OP_SELL);// Если достигли верхней границы канала
		}
		if (Ask<=pl+2*Point && Ask>=pl-2*Point) 
		{
			ObjectCreate(StringConcatenate("GC_Channel1 ", objId++), OBJ_TREND, 0, Time[xh2], h2, Time[xh1], h1);
			ObjectCreate(StringConcatenate("GC_Channel2 ", objId++), OBJ_TREND, 0, Time[xl2], l2, Time[xl1], l1);
			return (OP_BUY);// Если достигли нижней границы канала
		}
		
	}
	else
	{
		if (Bid>=ph-2*Point && Bid<=ph+2*Point) return (OP_BUY);// Если достигли верхней границы канала 
		if (Ask<=pl+2*Point && Ask>=pl-2*Point) return (OP_SELL);// Если достигли нижней границы канала
	}

	return -1;
}

//PK
/*int Kis(bool isEntry)
{
	int i;
	datetime time;
	double dp=0.0;
	double buy, sell;
	double hi=0.0, lo=0.0, avg=0.0, op=0.0, cl=0.0;
	double do_=0.0, dc=0.0;
	if (TimeHour(TimeCurrent())<=20) 
	{ _isBought = false; _isSold = false; return -1;}
	
	if (TimeMinute(TimeCurrent())==21 && (!_isBought || !_isSold))
	{
		hi = iHigh(NULL, PERIOD_D1, 0); lo = iLow(NULL, PERIOD_D1, 0); avg = (hi+lo)/2;
		op = iOpen(NULL, PERIOD_D1, 0); cl = iClose(NULL, PERIOD_D1, 0);
		do_ = MathAbs(op-avg); dc = MathAbs(cl-avg); 
		
		time = StrToTime("7:00");
		i = iBarShift(_symbol, _period, time);

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
*/
int PSSignals::ZigZag(bool isEntry)
{
	double zz0=0.0, zz1=0.0;
	int i=0;
	int totalBars = Bars-1;

	// Finding first up/down.
	while (i<totalBars && zz0==0.0)
	{ 
		zz0 = iCustom(_symbol, _period, "ZigZag", 20, 10, 3, 0, i); i++;	
	}

	// Continue finding second down/up.
	while (i<totalBars && zz1==0.0)
	{ 
		zz1 = iCustom(_symbol, _period, "ZigZag", 20, 10, 3, 0, i); i++;	
	}

	if (isEntry)   //для открытия
	{ 	
		if (zz0>zz1)	return (OP_BUY);
		if (zz0<zz1)	return (OP_SELL);
	}	
	else
	{
		if (zz0>zz1)	return (OP_SELL);
		if (zz0<zz1)	return (OP_BUY);
	}
   return -1; //нет сигнала
}

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

// Signal is wrong!
int PSSignals::Collaps(bool isEntry)
{
	int maPeriod=120;
	double Laguerre;
	double cci;
	double MA0, MA1;
  
	Laguerre=iCustom(_symbol, _period, "Laguerre", 0.7, 100, 0, 1);
	cci=iCCI(_symbol, _period, 14, PRICE_CLOSE, 0);
	MA0=iMA(_symbol, _period, maPeriod,0,MODE_EMA,PRICE_MEDIAN,0);
	MA1=iMA(_symbol, _period, maPeriod,0,MODE_EMA,PRICE_MEDIAN,1);
  
	if (isEntry)   //для открытия
	{ 	
		if (Laguerre==0 && MA0>MA1 && cci<-10) return (OP_BUY);
   	if (Laguerre==1 && MA0<MA1 && cci>10) return (OP_SELL);
	}	
	else
	{
		if (Laguerre>0.9) return (OP_BUY);
		if (Laguerre<0.1) return (OP_SELL);
	}
   return -1; //нет сигнала
}

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

int PSSignals::Envelop2(bool isEntry)
{
	int slowMAPeriod=20;
	double Deviation=0.13;
	int Mode=MODE_SMA;//0-sma, 1-ema, 2-smma, 3-lwma
	int Price=PRICE_CLOSE;//0-close, 1-open, 2-high, 3-low, 4-median, 5-typic, 6-wieight
	double maSlow, maFast;
	
   double envH0, envL0;
	envH0=iEnvelopes(_symbol, _period, slowMAPeriod, Mode, 0, Price, Deviation, MODE_UPPER, 0); 
	envL0=iEnvelopes(_symbol, _period, slowMAPeriod, Mode, 0, Price, Deviation, MODE_LOWER, 0); 

	maFast=iMA(_symbol, _period, slowMAPeriod, 0, Mode, Price, 0); 
	maSlow=iMA(_symbol, _period, slowMAPeriod+2, 0, Mode, Price, 0); 
	
	//----- условия для совершения операции
	if (isEntry)   //для открытия
	{ 	
		if (Bid<envL0 && maFast>maSlow) return (OP_BUY);
		if (Ask>envH0 && maFast<maSlow) return (OP_SELL);
	}
	else //для закрытия
	{
		if (Bid<envL0 && maFast>=maSlow) return (OP_SELL);
		if (Ask>envH0 && maFast<=maSlow) return (OP_BUY);
	}
   return -1; //нет сигнала
}

int PSSignals::Envelop(bool isEntry)
{
	int slowMAPeriod=21;
	double Deviation=0.6;
	int Mode=MODE_SMA;//0-sma, 1-ema, 2-smma, 3-lwma
	int Price=PRICE_CLOSE;//0-close, 1-open, 2-high, 3-low, 4-median, 5-typic, 6-wieight
	
   double envH0, envL0, m0;
   double envH1, envL1, m1;
	envH0=iEnvelopes(_symbol, _period, slowMAPeriod, Mode, 0, Price, Deviation, MODE_UPPER, 0); 
	envL0=iEnvelopes(_symbol, _period, slowMAPeriod, Mode, 0, Price, Deviation, MODE_LOWER, 0); 
	envH1=iEnvelopes(_symbol, _period, slowMAPeriod, Mode, 0, Price, Deviation, MODE_UPPER, 1); 
	envL1=iEnvelopes(_symbol, _period, slowMAPeriod, Mode, 0, Price, Deviation, MODE_LOWER, 1); 

	m0 = (Low[0]+High[0])/2;	m1 = (Low[1]+High[1])/2;
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

int PSSignals::Wpr(bool isEntry)
{
	int    m=20;
   double wpr0, wpr1, wpr2;
//----
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

int PSSignals::slowMAPeriod(bool isEntry)
{
	//параметры средних
	int SlowMA=7;
	int FastMA=5;
	int MODE_MA    = MODE_EMA; // метод вычисления средних
	int PRICE_MA   = PRICE_CLOSE; // метод вычисления средних

   double sCur, fCur, sPre1, fPre1, sPre2, fPre2;
//----

	sCur=iMA(_symbol, _period, SlowMA, 0, MODE_MA, PRICE_MA, 0);
	sPre1=iMA(_symbol, _period, SlowMA, 0, MODE_MA, PRICE_MA, 1);
	sPre2=iMA(_symbol, _period, SlowMA, 0, MODE_MA, PRICE_MA, 2);

	fCur=iMA(_symbol, _period, FastMA, 0, MODE_MA, PRICE_MA, 0);
	fPre1=iMA(_symbol, _period, FastMA, 0, MODE_MA, PRICE_MA, 1);
	fPre2=iMA(_symbol, _period, FastMA, 0, MODE_MA, PRICE_MA, 2);

	//----- условия для совершения операции
	if (isEntry)   //для открытия
	{ 	
		if (fCur>sCur && fPre1>sPre1 && fPre2<sPre2) return (OP_BUY);
		if (fCur<sCur && fPre1<sPre1 && fPre2>sPre2) return (OP_SELL);
	}
	else //для закрытия
	{
		if (fCur>sCur && fPre1>sPre1 && fPre2<sPre2) return (OP_SELL);
		if (fCur<sCur && fPre1<sPre1 && fPre2>sPre2) return (OP_BUY);
	}
 
   return -1; //нет сигнала
}

int PSSignals::Macd2(bool isEntry)
{
	int fMA=7;
	int sMA=36;
	int sigMA=7;
	int PRICE = PRICE_CLOSE;
	double Level=0.001;
	
	int i=0;
	double Range, Delta0, Delta1;

	Range = iATR(_symbol, _period, 200,1)*Level;
	
	Delta0 = iMACD(_symbol, _period, fMA,sMA,sigMA,PRICE,MODE_MAIN,0)
		- iMACD(_symbol, _period, fMA,sMA,sigMA,PRICE,MODE_SIGNAL,0);
	
	Delta1 = iMACD(_symbol, _period, fMA,sMA,sigMA,PRICE,MODE_MAIN,1)
		- iMACD(_symbol, _period, fMA,sMA,sigMA,PRICE,MODE_SIGNAL,1);

	if (isEntry)   //для открытия
	{ 	
		if (Delta0>Range && Delta1<Range) return (OP_BUY);
		if (Delta0<-Range && Delta1>-Range) return (OP_SELL);
	}
	else //для закрытия
	{
		if(Delta0<0) return (OP_BUY);
		if(Delta0>0) return (OP_SELL);
	}
   return -1; //нет сигнала
}

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

//---- получить значение
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
//---- получить скользящие средние 
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
//---- получить скользящие средние 
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

int PSSignals::SidusSinc(bool isEntry)
{
	//параметры 
	int MABluFast  = 5; // синий
	int MABluSlow  = 8; //  канал 
	int MARedFast  = 16; // красный
	int MARedSlow  = 28; //  канал 
	int MODE_MA    = MODE_LWMA; // метод вычисления средних
	int PRICE_MA   = PRICE_WEIGHTED; // метод вычисления средних
	
	// int PERIOD     = PERIOD_H1; // на каком периоде работать
	// int PERIOD2    = PERIOD_D1; // на каком периоде работать
	// int PERIOD3    = PERIOD_M30; // на каком периоде работать
	// int PERIOD4    = PERIOD_H4; // на каком периоде работать
	int PERIOD     = _period; // на каком периоде работать
	int PERIOD2    = GetNextTimeFrame(_period, 2); // на каком периоде работать
	int PERIOD3    = GetPreviousTimeFrame(_period, 1); // на каком периоде работать
	int PERIOD4    = GetNextTimeFrame(_period, 1); // на каком периоде работать

	if (PERIOD2 == -1 || PERIOD3 == -1 || PERIOD4 == -1) {
		
	   _fileLog.Error(StringConcatenate("PSSignals. Invalid next/previous Time frame. Signal Id: ", _signalId));
		return -1;
	}
	
   double rh1f, rh1s, rd1f, rd1s, rh4f, rh4s, rm30f, rm30s;
//---- получить скользящие средние 
   rm30f	=iMA(_symbol, PERIOD3, MARedFast, 0, MODE_MA, PRICE_MA, 0);
   rm30s	=iMA(_symbol, PERIOD3, MARedSlow, 0, MODE_MA, PRICE_MA, 0);
   
	rh1f	=iMA(_symbol, PERIOD, MARedFast, 0, MODE_MA, PRICE_MA, 0);
   rh1s	=iMA(_symbol, PERIOD, MARedSlow, 0, MODE_MA, PRICE_MA, 0);
   
	rh4f	=iMA(_symbol, PERIOD4, MARedFast, 0, MODE_MA, PRICE_MA, 0);
   rh4s	=iMA(_symbol, PERIOD4, MARedSlow, 0, MODE_MA, PRICE_MA, 0);
   
	rd1f	=iMA(_symbol, PERIOD2, MARedFast, 0, MODE_MA, PRICE_MA, 0);
   rd1s	=iMA(_symbol, PERIOD2, MARedSlow, 0, MODE_MA, PRICE_MA, 0);
   
	//----- условия для совершения операции
	if (isEntry)   //для открытия
	{ 	
//		if ((rh1f>rh1s) && (rd1f>rd1s) && (rh4f>rh4s) && (Ask<=rh1f-35*Point))  return (OP_BUY); 
//		if ((rh1f<rh1s) && (rd1f<rd1s) && (rh4f<rh4s) && (Bid>=rh1f+35*Point))  return (OP_SELL); 
		if ((rh1f>rh1s) && (rh4f>rh4s) && (rd1f>rd1s) && (rm30f>rm30s) && (Ask<=rh1f-15*Point))  
			return (OP_BUY);   //для евры
		
		if ((rh1f<rh1s) && (rh4f<rh4s) && (rd1f<rd1s) && (rm30f<rm30s) && (Bid>=rh1f+15*Point))  
			return (OP_SELL);  //для евры
	}
	else //для закрытия
	{	
		if (rh1f<rh1s)  return (OP_BUY); 
		if (rh1f>rh1s)  return (OP_SELL);  
	}
 
   return -1; //нет сигнала
}

// This signal is absolutely wrong for D1, H4, H1, M30.
int PSSignals::BlackSys(bool isEntry)
{
	//параметры средних
	int slowMAPeriod  = 20; //  канал 
	int fastMAPeriod  = 17; //  канал 
	int MODE_MA    = MODE_SMA; // метод вычисления средних
	int PRICE_MA   = PRICE_MEDIAN; // метод вычисления средних

	//параметры RSI
	int RSI_PERIOD  = 3; 

   double rs, rf, rsi, rsiPre;
//---- получить скользящие средние 
   rs=iMA(_symbol, _period, slowMAPeriod, 0, MODE_MA, PRICE_MA, 0);
   rf=iMA(_symbol, _period, fastMAPeriod, 0, MODE_MA, PRICE_MA, 0);
   
   rsi = iRSI(_symbol, _period, RSI_PERIOD, PRICE_WEIGHTED, 0);
   rsiPre = iRSI(_symbol, _period, RSI_PERIOD, PRICE_WEIGHTED, 1);
	//----- условия для совершения операции
	if (isEntry)   //для открытия
	{ 	
		if ((rsiPre<30) && (rsi>30) && (Ask<rs) && (rf>rs))  return (OP_BUY);   
		if ((rsiPre>70) && (rsi<70) && (Bid>rs) && (rf<rs))  return (OP_SELL);   
	}
	else //для закрытия
	{	
		if ((rsiPre<30) && (rsi>30) && (Ask<rs) && (rf>rs))  return (OP_SELL);  
		if ((rsiPre>70) && (rsi<70) && (Bid>rs) && (rf<rs))  return (OP_BUY); 
	}
 
   return -1; //нет сигнала
}

int PSSignals::Vegas4H(bool isEntry)
{
	//параметры средних
	int       MA5=5;//для недельного
	int       MA21=21;//для недельного
	int       MA8=8;//для 1Н и 4Н
	int       MA55=55;//для 1Н и 4Н
	int       RiskModel=1;
	
	// H4 -> D1 -> W1
	int nextPeriod2 = GetNextTimeFrame(_period, 2);
	if (nextPeriod2 == -1) {
	   _fileLog.Error(StringConcatenate("PSSignals. Invalid next 2 Time frame. Signal Id: ", _signalId));
		return -1;
	}

	// H4 -> H1
	int previousPeriod = GetPreviousTimeFrame(_period, 1);
	if (previousPeriod == -1) {
	   _fileLog.Error(StringConcatenate("PSSignals. Invalid previous Time frame. Signal Id: ", _signalId));
		return -1;
	}

   double w5Pre, w21Pre, w5Cur, w21Cur, h, h11Pre, h11Cur, h12Pre, h12Cur, dwCur, dwPre;
//---- получить скользящие средние 
	//w5Cur=iMA(NULL, PERIOD_W1, MA5, 0, MODE_SMA, PRICE_MEDIAN, 0);
	w5Cur=iMA(_symbol, nextPeriod2, MA5, 0, MODE_SMA, PRICE_MEDIAN, 0);
	w21Cur=iMA(_symbol, nextPeriod2, MA21, 0, MODE_EMA, PRICE_MEDIAN, 0);
	w5Pre=iMA(_symbol, nextPeriod2, MA5, 0, MODE_SMA, PRICE_MEDIAN, 1);
	w21Pre=iMA(_symbol, nextPeriod2, MA21, 0, MODE_EMA, PRICE_MEDIAN, 1);

	dwCur = w5Cur-w21Cur; dwPre = w5Pre-w21Pre;
	
	//h11Cur=iMA(NULL, PERIOD_H1, MA8, 0, MODE_SMA, PRICE_CLOSE, 0);
	h11Cur=iMA(_symbol, previousPeriod, MA8, 0, MODE_SMA, PRICE_CLOSE, 0);
	h12Cur=iMA(_symbol, previousPeriod, MA55, 0, MODE_SMA, PRICE_MEDIAN, 0);
	h11Pre=iMA(_symbol, previousPeriod, MA8, 0, MODE_SMA, PRICE_CLOSE, 1);
	h12Pre=iMA(_symbol, previousPeriod, MA55, 0, MODE_SMA, PRICE_MEDIAN, 1);

	//h=iMA(NULL, PERIOD_H4, MA55, 0, MODE_SMA, PRICE_MEDIAN, 0);
	h=iMA(_symbol, _period, MA55, 0, MODE_SMA, PRICE_MEDIAN, 0);
	//----- условия для совершения операции
	if (isEntry)   //для открытия
	{ 	
		if ((h12Cur>h11Cur) && (h12Pre>h11Pre) && (h11Cur>h11Pre) 
				&& (w5Cur>w21Cur) && (w5Pre>w21Pre) && (dwCur>dwPre)) return (OP_BUY);   
		if ((h12Cur<h11Cur) && (h12Pre<h11Pre) && (h11Cur<h11Pre) 
				&& (w5Cur<w21Cur) && (w5Pre<w21Pre) && (dwCur<dwPre)) return (OP_SELL);   
	}
	else //для закрытия
	{	
		if ((h11Cur<h11Pre) || (Bid>h+89*Point)) return (OP_BUY);   
		if ((h11Cur>h11Pre) || (Bid<h-89*Point)) return (OP_SELL);   
	}
 
   return -1; //нет сигнала
}

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

int PSSignals::DifMAS(bool isEntry)
{
	//параметры средних 
	int MA5=25;
	int MA7=28;
	int MODE_MA=MODE_EMA;
	int PRICE=PRICE_MEDIAN;

   double dxCurA, dxPreA;
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

	//----- условия для совершения операции
	if (isEntry)   //для открытия
	{
		if ((dxCurA>0) && (dxPreA<0))	return (OP_BUY);
		if ((dxCurA<0) && (dxPreA>0))	return (OP_SELL);
	}
	else //для закрытия
	{	
		if ((dxCurA>0) && (dxPreA<0))	return (OP_SELL);
		if ((dxCurA<0) && (dxPreA>0))	return (OP_BUY);
	}
 
   return -1; //нет сигнала
}

int PSSignals::CCI()
{
   int periodCCI = 55;//Период усреднения для вычисления индикатора.
   int applied_price = 0;//Используемая цена. Может быть любой из ценовых констант.
   int shift = 0;//сдвиг относительно текущего бара на указанное количество периодов назад
   int CCI_High = 100;
   int CCI_Low = 100;
   
   double CCICurrent=iCCI(_symbol, _period, periodCCI,applied_price,shift);
   double CCIPrevious=iCCI(_symbol, _period, periodCCI,applied_price,shift+1);
    
    int vSignal = 0;
    if(CCICurrent<-CCI_Low && CCIPrevious>-CCI_Low) 
	 	return (OP_BUY); 

	if(CCICurrent>CCI_High && CCIPrevious<CCI_High) 
		return (OP_SELL);
    
   return -1; //нет сигнала
}