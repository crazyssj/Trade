//+------------------------------------------------------------------+
//|                                                 PSTrailingSL.mq4 |
//|                                   Copyright 2019, PSInvest Corp. |
//|                                          https://www.psinvest.eu |
//+------------------------------------------------------------------+
// Tailing functions
#property copyright "Copyright 2019, PSInvest Corp."
#property link      "https://www.psinvest.eu"
#property version   "1.00"
#property strict

#include <PSMarket.mqh>
#include <FileLog.mqh>

class PSTrailingSL
{
	public:
		PSTrailingSL(CFileLog *fileLog, string symbol, int period);
		~PSTrailingSL();
		bool CheckSystemIdIsValid(int signalId);
		bool Trailing(int systemId, int ticketId, double &stopLoss, bool trailingInLoss = false);
	private:
		CFileLog *_fileLog;
		string _symbol;
		int _period;
        int _systemId;
        datetime _sdtPrevtime;
        int _indent;
        int _orderType;
        double _orderSL;
        double _orderOpenPrice;
        double _marketStopLevel;
        double _marketSpread;

        bool trailingByFractals(int period, int bars, double &stopLoss, bool trailingInLoss);
        bool trailingByShadows(int period, int bars, double &stopLoss, bool trailingInLoss);
        bool trailingStairs(int trailingDistance,int trailingStep, double &stopLoss);
};

PSTrailingSL::PSTrailingSL(CFileLog *fileLog, string symbol, int period)
{
	_fileLog = fileLog;
	_symbol = symbol;
	_period = period;
    
    _sdtPrevtime = 0;
    _indent = 0;
	// if (_period > PERIOD_D1) {
	// 	_fileLog.Error(StringConcatenate("PSSignals::PSSignals. Period shouldn't greater than PERIOD_D1. Current:", period));
	// }
}

PSTrailingSL::~PSTrailingSL()
{

}

bool PSTrailingSL::CheckSystemIdIsValid(int systemId)
{
	return systemId >= 1 && systemId <= 11;
}

// TODO: Must rewrite and test.
//  All OrderModify must add in one function. 

// systemId: number of trailing stop function
// trailingInLoss: true - trailing if order is in loss, false - SL moves only in profit
bool PSTrailingSL::Trailing(int systemId, int ticketId, double &stopLoss, bool trailingInLoss)
{
	_systemId = systemId;
    stopLoss = 0.0;

    if(!OrderSelect(ticketId, SELECT_BY_TICKET))
    {
        _fileLog.Warning(StringConcatenate("PSTrailingSL::TrailingStop ticketId #", ticketId, " is not valid."));
        return false;
    }

    _marketStopLevel = MarketInfo(_symbol,MODE_STOPLEVEL);
    _marketSpread = MarketInfo(_symbol,MODE_SPREAD);
    _orderType = OrderType();
    _orderSL = OrderStopLoss();
    _orderOpenPrice = OrderOpenPrice();

	switch (systemId)
	{
	   // TODO: All functins should return bool!return sometime errors
		//case 1: return trailingByFractals(GetPreviousTimeFrame(_period, 1), 4/*bars: 4 or more*/, stopLoss, trailingInLoss); break;
		case 1: return trailingByFractals(_period, 4/*bars: 4 or more*/, stopLoss, trailingInLoss);
		case 2: return trailingByShadows(_period, 1/*bars: 1 or more*/, stopLoss, trailingInLoss);
		case 3: return trailingStairs(300 /*trailingDistance: distance after price*/, 100 /*trailingStep: moving step after price up trailingDistance */, stopLoss);
      // TODO: return sometime errors
		case 4: trailingUdavka(ticketId, 200 /*trl_dist_1*/, 300/*level_1*/, 150/*trl_dist_2*/, 500/* level_2 */, 100/*trl_dist_3*/); break;
		case 5: trailingByTime(ticketId, /*10 for 60 TF*/_period / 6/*interval in min */, 100/*trailingStep*/,trailingInLoss); break;
      // TODO: Need to be changed..
		case 6: trailingByATR(ticketId, _period, 12/*atr1_period*/, 0/*atr1_shift*/, 20/*atr2_period*/, 0/*atr2_shift*//*, 1000*//*coeff*/, trailingInLoss); break;
      // TODO: Improvements are needed in parameters
		case 7: trailingRatchetB(ticketId, 50/*pf_level_1*/, 100/*pf_level_2*/, 250/*pf_level_3*/, 10/*ls_level_1*/, 50/*ls_level_2*/, 100/*ls_level_3*/, trailingInLoss); break;
      // TODO: Improvements are needed in parameters, return sometime errors
		case 8: trailingByPriceChannel(ticketId, GetPreviousTimeFrame(_period, 1), /* 4 -117 *//* 3 -98*/ /* 2 -95 */ 2 /*iBars: 1 or more*/, indent); break;
      // TODO: Improvements are needed in parameters, return sometime errors
		case 9: trailingByMA(ticketId, _period, 5/*iMAPeriod*/, 0/*iMAShift*/, 3/*MAMethod*/,0/*iMAApplPrice*/, 2 /*bars iShift*/, indent); break;
      // TODO: Improvements are needed in parameters
		case 10: trailingFiftyFifty(ticketId, _period,  /* 0.3 -72 */ /* 0.5 -50 */ /* 0.75 -32 */ /* 0.8 -11 */ 0.8 /* 0.85 -31 */ /*dCoeff*/, trailingInLoss); break;
      // TODO: Improvements are needed in parameters, return sometime errors
		case 11: KillLoss(ticketId, 0.8/*dSpeedCoeff*/); break;

		default: 
		{
		   _fileLog.Error(StringConcatenate("PSTrailingSL::Trailing Invalid systemId: ", systemId));
		   return false;
		}
	}
	
	return true;
}

//+------------------------------------------------------------------+
//| ТРЕЙЛИНГ ПО ФРАКТАЛАМ                                            |
//| Функции передаётся тикет позиции, количество баров в фрактале,   |
//| и отступ (пунктов) - расстояние от макс. (мин.) свечи, на        |
//| которое переносится стоплосс (от 0), trailingInLoss - тралить ли в    |
//| зоне убытков                                                     |
//+------------------------------------------------------------------+
bool PSTrailingSL::trailingByFractals(int period, int bars, double &stopLoss, bool trailingInLoss)
{
    stopLoss = 0.0;
   int i, z; // counters
   int extr_n; // номер ближайшего экстремума bars-барного фрактала 
   double temp; // служебная переменная
   int after_x, be4_x; // свечей после и до пика соответственно
   int ok_be4, ok_after; // флаги соответствия условию (1 - неправильно, 0 - правильно)
   int sell_peak_n= 0, buy_peak_n = 0; // номера экстремумов ближайших фракталов на продажу (для поджатия дл.поз.) и покупку соответсвенно   
   
   // проверяем переданные значения
   if (bars<=3)
   {
        _fileLog.Error(StringConcatenate("Trailing system Id:", _systemId, " bars should be >= 4. Value:", bars));
        return false;
   } 
   
   temp = bars;
      
   if (MathMod(bars,2)==0)
    extr_n = (int)(temp/2);
   else                
    extr_n = (int)MathRound(temp/2);
      
   // баров до и после экстремума фрактала
   after_x = bars - extr_n;
   if (MathMod(bars,2)!=0)
    be4_x = bars - extr_n;
   else
    be4_x = bars - extr_n - 1;    
   
   // если длинная позиция (OP_BUY), находим ближайший фрактал на продажу (т.е. экстремум "вниз")
   if (_orderType==OP_BUY)
      {
      // находим последний фрактал на продажу
      for (i=extr_n;i<iBars(_symbol,period);i++)
         {
         ok_be4 = 0; ok_after = 0;
         
         for (z=1;z<=be4_x;z++)
            {
            if (iLow(_symbol,period,i)>=iLow(_symbol,period,i-z)) 
               {
               ok_be4 = 1;
               break;
               }
            }
            
         for (z=1;z<=after_x;z++)
            {
            if (iLow(_symbol,period,i)>iLow(_symbol,period,i+z)) 
               {
               ok_after = 1;
               break;
               }
            }            
         
         if ((ok_be4==0) && (ok_after==0))                
            {
            sell_peak_n = i; 
            break;
            }
         }
     
      double sl = iLow(_symbol,period,sell_peak_n)-indent*Point;
      // если тралить в убытке
      if (trailingInLoss)
         {
         // если новый стоплосс лучше имеющегося (в т.ч. если стоплосс == 0, не выставлен)
         // а также если курс не слишком близко, ну и если стоплосс уже не был перемещен на рассматриваемый уровень         
         if ((sl>_orderSL) && (sl<Bid-_marketStopLevel*Point))
            {
                stopLoss = sl;
                return true;
            }
         }
      // если тралить только в профите, то
      else
         {
         // если новый стоплосс лучше имеющегося И курса открытия, а также не слишком близко к текущему курсу
         if ((sl>_orderSL) && (sl>_orderOpenPrice) && (sl<Bid-_marketStopLevel*Point))
            {
                stopLoss = sl;
                return true;
            }
         }
      }
      
   
   // если короткая позиция (OP_SELL), находим ближайший фрактал на покупку (т.е. экстремум "вверх")
   if (_orderType==OP_SELL)
      {
      // находим последний фрактал на продажу
      for (i=extr_n;i<iBars(_symbol,period);i++)
         {
         ok_be4 = 0; ok_after = 0;
         
         for (z=1;z<=be4_x;z++)
            {
            if (iHigh(_symbol,period,i)<=iHigh(_symbol,period,i-z)) 
               {
               ok_be4 = 1;
               break;
               }
            }
            
         for (z=1;z<=after_x;z++)
            {
            if (iHigh(_symbol,period,i)<iHigh(_symbol,period,i+z)) 
               {
               ok_after = 1;
               break;
               }
            }            
         
         if ((ok_be4==0) && (ok_after==0))                
            {
            buy_peak_n = i;
            break;
            }
         }        
      
      double sl = iHigh(_symbol,period,buy_peak_n)+(indent+_marketSpread)*Point;
      // если тралить в убытке
      if (trailingInLoss)
         {
         if (((sl<_orderSL) || (_orderSL==0)) && (sl>Ask+_marketStopLevel*Point))
            {
                stopLoss = sl;
                return true;
            }
         }      
      // если тралить только в профите, то
      else
         {
         // если новый стоплосс лучше имеющегося И курса открытия
         if ((((sl<_orderSL) || (_orderSL==0))) && (sl<_orderOpenPrice) && (sl>Ask+_marketStopLevel*Point))
            {
                stopLoss = sl;
                return true;
            }
         }
      }      
   }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| ТРЕЙЛИНГ ПО ТЕНЯМ N СВЕЧЕЙ                                       |
//| Функции передаётся тикет позиции, количество баров, по теням     |
//| которых необходимо трейлинговать (от 1 и больше) и отступ        |
//| (пунктов) - расстояние от макс. (мин.) свечи, на которое         |
//| переносится стоплосс (от 0), trailingInLoss - тралить ли в лоссе      | 
//+------------------------------------------------------------------+
//void trailingByShadows(int ticketId,int tmfrm,int bars, int indent,bool trailingInLoss)
bool PSTrailingSL::trailingByShadows(int period, int bars, double &stopLoss, bool trailingInLoss)
{  
   int i; // counter
   double new_extremum = 0.0;
   
   if (bars < 1)
   {
        _fileLog.Error(StringConcatenate("Trailing system Id:", _systemId, " bars should be >= 1. Value:", bars));
        return false;
   } 
   
   // если длинная позиция (OP_BUY), находим минимум bars свечей
   if (_orderType==OP_BUY)
      {
      for(i=1;i<=bars;i++)
         {
         if (i==1) new_extremum = iLow(_symbol,tmfrm,i);
         else 
         if (new_extremum>iLow(_symbol,tmfrm,i)) new_extremum = iLow(_symbol,tmfrm,i);
         }         
      
      double sl = new_extremum - indent*Point;
      // если тралим и в зоне убытков
      if (trailingInLoss==true)
    {
         // если найденное значение "лучше" текущего стоплосса позиции, переносим 
         if ((((sl)>_orderSL) || (_orderSL==0)) && (sl<Bid-_marketStopLevel*Point))
         {
            stopLoss = sl;
            return true;
         }
    }
      else
         {
         // если новый стоплосс не только лучше предыдущего, но и курса открытия позиции
         if ((((sl)>_orderSL) || (_orderSL==0)) && ((sl)>_orderOpenPrice) && (sl<Bid-_marketStopLevel*Point))
         {
            stopLoss = sl;
            return true;
         }
         }
      }
      
   // если короткая позиция (OP_SELL), находим минимум bars свечей
   if (_orderType==OP_SELL)
      {
      for(i=1;i<=bars;i++)
         {
         if (i==1) new_extremum = iHigh(_symbol,tmfrm,i);
         else 
         if (new_extremum<iHigh(_symbol,tmfrm,i)) new_extremum = iHigh(_symbol,tmfrm,i);
         }         
        double sl = new_extremum + (indent + _marketSpread)*Point;
      // если тралим и в зоне убытков
      if (trailingInLoss==true)
         {
         // если найденное значение "лучше" текущего стоплосса позиции, переносим 
         if ((((sl)<_orderSL) || (_orderSL==0)) && (sl>Ask+_marketStopLevel*Point))
         {
            stopLoss = sl;
            return true;
         }
         }
      else
         {
         // если новый стоплосс не только лучше предыдущего, но и курса открытия позиции
         if ((((sl)<_orderSL) || (_orderSL==0)) && ((sl)<_orderOpenPrice) && (sl>Ask+_marketStopLevel*Point))
         {
            stopLoss = sl;
            return true;
         }
         }      
      }      
   }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| ТРЕЙЛИНГ СТАНДАРТНЫЙ-СТУПЕНЧАСТЫЙ                                |
//| Функции передаётся тикет позиции, расстояние от курса открытия,  |
//| на котором трейлинг запускается (пунктов) и "шаг", с которым он  |
//| переносится (пунктов)                                            |
//| Пример: при +30 стоп на +10, при +40 - стоп на +20 и т.д.        |
//+------------------------------------------------------------------+

bool PSTrailingSL::trailingStairs(int trailingDistance,int trailingStep, double &stopLoss)
   { 
   
   double nextstair; // ближайшее значение курса, при котором будем менять стоплосс

   // проверяем переданные значения
   if ((trailingDistance<_marketStopLevel) || (trailingStep<1) || (trailingDistance<trailingStep))
      {
        _fileLog.Error(StringConcatenate("Trailing system Id:", _systemId, " parameters is not valid."));
        return false;
      } 
   
   // если длинная позиция (OP_BUY)
   if (_orderType==OP_BUY)
      {
      // расчитываем, при каком значении курса следует скорректировать стоплосс
      // если стоплосс ниже открытия или равен 0 (не выставлен), то ближайший уровень = курс открытия + trailingDistance + спрэд
      if ((_orderSL==0) || (_orderSL<_orderOpenPrice))
      nextstair = _orderOpenPrice + trailingDistance*Point;
         
      // иначе ближайший уровень = текущий стоплосс + trailingDistance + trailingStep + спрэд
      else
      nextstair = _orderSL + trailingDistance*Point;

      // если текущий курс (Bid) >= nextstair и новый стоплосс точно лучше текущего, корректируем последний
      if (Bid>=nextstair)
         {
         if (((_orderSL==0) || (_orderSL<_orderOpenPrice)) 
               && (_orderOpenPrice + trailingStep*Point<Bid-_marketStopLevel*Point)) 
            {
            if (!OrderModify(ticketId,_orderOpenPrice,_orderOpenPrice + trailingStep*Point,OrderTakeProfit(),OrderExpiration()))
            Print("Не удалось модифицировать стоплосс ордера №",OrderTicket(),". Ошибка: ",GetLastError());
            }
         }
      else
         {
         if (!OrderModify(ticketId,_orderOpenPrice,_orderSL + trailingStep*Point,OrderTakeProfit(),OrderExpiration()))
         Print("Не удалось модифицировать стоплосс ордера №",OrderTicket(),". Ошибка: ",GetLastError());
         }
      }
      
   // если короткая позиция (OP_SELL)
   if (_orderType==OP_SELL)
      { 
      // расчитываем, при каком значении курса следует скорректировать стоплосс
      // если стоплосс ниже открытия или равен 0 (не выставлен), то ближайший уровень = курс открытия + trailingDistance + спрэд
      if ((_orderSL==0) || (_orderSL>_orderOpenPrice))
      nextstair = _orderOpenPrice - (trailingDistance + _marketSpread)*Point;
      
      // иначе ближайший уровень = текущий стоплосс + trailingDistance + trailingStep + спрэд
      else
      nextstair = _orderSL - (trailingDistance + _marketSpread)*Point;
       
      // если текущий курс (Аск) >= nextstair и новый стоплосс точно лучше текущего, корректируем последний
      if (Ask<=nextstair)
         {
         if (((_orderSL==0) || (_orderSL>_orderOpenPrice))
               && (_orderOpenPrice - (trailingStep + _marketSpread)*Point>Ask+_marketStopLevel*Point))
            {
            if (!OrderModify(ticketId,_orderOpenPrice,_orderOpenPrice - (trailingStep + _marketSpread)*Point,OrderTakeProfit(),OrderExpiration()))
            Print("Не удалось модифицировать стоплосс ордера №",OrderTicket(),". Ошибка: ",GetLastError());
            }
         }
      else
         {
         if (!OrderModify(ticketId,_orderOpenPrice,_orderSL- (trailingStep + _marketSpread)*Point,OrderTakeProfit(),OrderExpiration()))
         Print("Не удалось модифицировать стоплосс ордера №",OrderTicket(),". Ошибка: ",GetLastError());
         }
      }      
   }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| ТРЕЙЛИНГ СТАНДАРТНЫЙ-ЗАТЯГИВАЮЩИЙСЯ                              |
//| Функции передаётся тикет позиции, исходный трейлинг (пунктов) и  |
//| 2 "уровня" (значения профита, пунктов), при которых трейлинг     |
//| сокращаем, и соответствующие значения трейлинга (пунктов)        |
//| Пример: исходный трейлинг 30 п., при +50 - 20 п., +80 и больше - |
//| на расстоянии в 10 пунктов.                                      |
//+------------------------------------------------------------------+

void trailingUdavka(int ticketId,int trl_dist_1,int level_1,int trl_dist_2,int level_2,int trl_dist_3)
   {  
   
   double newstop = 0.0; // новый стоплосс
   double trldist = 0.0; // расстояние трейлинга (в зависимости от "пройденного" может = trl_dist_1, trl_dist_2 или trl_dist_3)

   // проверяем переданные значения
   if ((trl_dist_1<_marketStopLevel) || (trl_dist_2<_marketStopLevel) || (trl_dist_3<_marketStopLevel) || 
   (level_1<=trl_dist_1) || (level_2<=trl_dist_1) || (level_2<=level_1) || (ticketId==0) || (!OrderSelect(ticketId,SELECT_BY_TICKET,MODE_TRADES)))
      {
      Print("Трейлинг функцией trailingUdavka() невозможен из-за некорректности значений переданных ей аргументов.");
      return;
      } 
   
   // если длинная позиция (OP_BUY)
   if (_orderType==OP_BUY)
      {
      // если профит <=trl_dist_1, то trldist=trl_dist_1, если профит>trl_dist_1 && профит<=level_1*Point ...
      if ((Bid-_orderOpenPrice)<=level_1*Point) trldist = trl_dist_1;
      if (((Bid-_orderOpenPrice)>level_1*Point) && ((Bid-_orderOpenPrice)<=level_2*Point)) trldist = trl_dist_2;
      if ((Bid-_orderOpenPrice)>level_2*Point) trldist = trl_dist_3; 
            
      // если стоплосс = 0 или меньше курса открытия, то если тек.цена (Bid) больше/равна дистанции курс_открытия+расст.трейлинга
      if ((_orderSL==0) || (_orderSL<_orderOpenPrice))
         {
         if (Bid>(_orderOpenPrice + trldist*Point))
         newstop = Bid -  trldist*Point;
         }

      // иначе: если текущая цена (Bid) больше/равна дистанции текущий_стоплосс+расстояние трейлинга, 
      else
         {
         if (Bid>(_orderSL + trldist*Point))
         newstop = Bid -  trldist*Point;
         }
      
      // модифицируем стоплосс
      if ((newstop>_orderSL) && (newstop<Bid-_marketStopLevel*Point))
         {
         if (!OrderModify(ticketId,_orderOpenPrice,newstop,OrderTakeProfit(),OrderExpiration()))
         Print("Не удалось модифицировать стоплосс ордера №",OrderTicket(),". Ошибка: ",GetLastError());
         }
      }
      
   // если короткая позиция (OP_SELL)
   if (_orderType==OP_SELL)
      { 
      // если профит <=trl_dist_1, то trldist=trl_dist_1, если профит>trl_dist_1 && профит<=level_1*Point ...
      if ((_orderOpenPrice-(Ask + _marketSpread*Point))<=level_1*Point) trldist = trl_dist_1;
      if (((_orderOpenPrice-(Ask + _marketSpread*Point))>level_1*Point) && ((_orderOpenPrice-(Ask + _marketSpread*Point))<=level_2*Point)) trldist = trl_dist_2;
      if ((_orderOpenPrice-(Ask + _marketSpread*Point))>level_2*Point) trldist = trl_dist_3; 
            
      // если стоплосс = 0 или меньше курса открытия, то если тек.цена (Ask) больше/равна дистанции курс_открытия+расст.трейлинга
      if ((_orderSL==0) || (_orderSL>_orderOpenPrice))
         {
         if (Ask<(_orderOpenPrice - (trldist + _marketSpread)*Point))
         newstop = Ask + trldist*Point;
         }

      // иначе: если текущая цена (Bid) больше/равна дистанции текущий_стоплосс+расстояние трейлинга, 
      else
         {
         if (Ask<(_orderSL - (trldist + _marketSpread)*Point))
         newstop = Ask +  trldist*Point;
         }
            
       // модифицируем стоплосс
      if (newstop>0)
         {
         if (((_orderSL==0) || (_orderSL>_orderOpenPrice)) && (newstop>Ask+_marketStopLevel*Point))
            {
            if (!OrderModify(ticketId,_orderOpenPrice,newstop,OrderTakeProfit(),OrderExpiration()))
            Print("Не удалось модифицировать стоплосс ордера №",OrderTicket(),". Ошибка: ",GetLastError());
            }
         else
            {
            if ((newstop<_orderSL) && (newstop>Ask+_marketStopLevel*Point))  
               {
               if (!OrderModify(ticketId,_orderOpenPrice,newstop,OrderTakeProfit(),OrderExpiration()))
               Print("Не удалось модифицировать стоплосс ордера №",OrderTicket(),". Ошибка: ",GetLastError());
               }
            }
         }
      }      
   }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| ТРЕЙЛИНГ ПО ВРЕМЕНИ                                              |
//| Функции передаётся тикет позиции, интервал (минут), с которым,   |
//| передвигается стоплосс и шаг трейлинга (на сколько пунктов       |
//| перемещается стоплосс, trailingInLoss - тралим ли в убытке            |
//| (т.е. с определённым интервалом подтягиваем стоп до курса        |
//| открытия, а потом и в профите, либо только в профите)            |
//+------------------------------------------------------------------+
void trailingByTime(int ticketId,int interval,int trailingStep,bool trailingInLoss)
   {
      
   // проверяем переданные значения
   if ((ticketId==0) || (interval<1) || (trailingStep<1) || !OrderSelect(ticketId,SELECT_BY_TICKET))
      {
      Print("Трейлинг функцией trailingByTime() невозможен из-за некорректности значений переданных ей аргументов.");
      return;
      }
      
   double minpast; // кол-во полных минут от открытия позиции до текущего момента 
   double times2change; // кол-во интервалов interval с момента открытия позиции (т.е. сколько раз должен был быть перемещен стоплосс) 
   double newstop; // новое значение стоплосса (учитывая кол-во переносов, которые должны были иметь место)
   
   // определяем, сколько времени прошло с момента открытия позиции
   minpast = MathFloor((TimeCurrent() - OrderOpenTime()) / 60);
      
   // сколько раз нужно было передвинуть стоплосс
   times2change = MathFloor(minpast / interval);
         
   // если длинная позиция (OP_BUY)
   if (_orderType==OP_BUY)
      {
      // если тралим в убытке, то отступаем от стоплосса (если он не 0, если 0 - от открытия)
      if (trailingInLoss==true)
         {
         if (_orderSL==0) newstop = _orderOpenPrice + times2change*(trailingStep*Point);
         else newstop = _orderSL + times2change*(trailingStep*Point); 
         }
      else
      // иначе - от курса открытия позиции
      newstop = _orderOpenPrice + times2change*(trailingStep*Point); 
         
      if (times2change>0)
         {
         if ((newstop>_orderSL) && (newstop<Bid- _marketStopLevel*Point))
            {
            if (!OrderModify(ticketId,_orderOpenPrice,newstop,OrderTakeProfit(),OrderExpiration()))
            Print("Не удалось модифицировать стоплосс ордера №",OrderTicket(),". Ошибка: ",GetLastError());
            }
         }
      }
      
   // если короткая позиция (OP_SELL)
   if (_orderType==OP_SELL)
      {
      // если тралим в убытке, то отступаем от стоплосса (если он не 0, если 0 - от открытия)
      if (trailingInLoss==true)
         {
         if (_orderSL==0) newstop = _orderOpenPrice - times2change*(trailingStep*Point) - _marketSpread*Point;
         else newstop = _orderSL - times2change*(trailingStep*Point) - _marketSpread*Point;
         }
      else
      newstop = _orderOpenPrice - times2change*(trailingStep*Point) - _marketSpread*Point;
                
      if (times2change>0)
         {
         if (((_orderSL==0) || (_orderSL<_orderOpenPrice)) && (newstop>Ask+_marketStopLevel*Point))
            {
            if (!OrderModify(ticketId,_orderOpenPrice,newstop,OrderTakeProfit(),OrderExpiration()))
            Print("Не удалось модифицировать стоплосс ордера №",OrderTicket(),". Ошибка: ",GetLastError());
            }
         else
         if ((newstop<_orderSL) && (newstop>Ask+_marketStopLevel*Point))
            {
            if (!OrderModify(ticketId,_orderOpenPrice,newstop,OrderTakeProfit(),OrderExpiration()))
            Print("Не удалось модифицировать стоплосс ордера №",OrderTicket(),". Ошибка: ",GetLastError());
            }
         }
      }      
   }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| ТРЕЙЛИНГ ПО ATR (Average True Range, Средний истинный диапазон)  |
//| Функции передаётся тикет позиции, период АТR и коэффициент, на   |
//| который умножается ATR. Т.о. стоплосс "тянется" на расстоянии    |
//| ATR х N от текущего курса; перенос - на новом баре (т.е. от цены |
//| открытия очередного бара)                                        |
//+------------------------------------------------------------------+
//atr1_period - Averaging period
// atr1_shift - Index of the value taken from the indicator buffer (shift relative to the current bar the given amount of periods ago).
// iATR(NULL,0,12,0)>iATR(NULL,0,20,0)) 
void trailingByATR(int ticketId,int atr_timeframe,int atr1_period,int atr1_shift,int atr2_period,int atr2_shift/*,double coeff*/,bool trailingInLoss)
   {
   // проверяем переданные значения   
   if ((ticketId==0) || (atr1_period<1) || (atr2_period<1) /*|| (coeff<=0)*/ || (!OrderSelect(ticketId,SELECT_BY_TICKET)) || 
   ((atr_timeframe!=1) && (atr_timeframe!=5) && (atr_timeframe!=15) && (atr_timeframe!=30) && (atr_timeframe!=60) && 
   (atr_timeframe!=240) && (atr_timeframe!=1440) && (atr_timeframe!=10080) && (atr_timeframe!=43200)) || (atr1_shift<0) || (atr2_shift<0))
      {
      Print("Трейлинг функцией trailingByATR() невозможен из-за некорректности значений переданных ей аргументов.");
      return;
      }
   
   double curr_atr1; // текущее значение ATR - 1
   double curr_atr2; // текущее значение ATR - 2
   double best_atr; // большее из значений ATR
   double atrXcoeff; // результат умножения большего из ATR на коэффициент
   double newstop; // новый стоплосс
   
   // текущее значение ATR-1, ATR-2
   curr_atr1 = iATR(_symbol,atr_timeframe,atr1_period,atr1_shift);
   curr_atr2 = iATR(_symbol,atr_timeframe,atr2_period,atr2_shift);
   
   // большее из значений
   best_atr = MathMax(curr_atr1,curr_atr2);
   
   // после умножения на коэффициент
   // PK
   //atrXcoeff = best_atr * coeff;
   atrXcoeff = best_atr * 100000 * Point;
   //Print("atrXcoeff: ", atrXcoeff);

   // если длинная позиция (OP_BUY)
   if (_orderType==OP_BUY)
      {
      // откладываем от текущего курса (новый стоплосс)
      newstop = Bid - atrXcoeff;           
      
      // если trailingInLoss==true (т.е. следует тралить в зоне лоссов), то
      if (trailingInLoss==true)      
         {
         // если стоплосс неопределен, то тралим в любом случае
         if ((_orderSL==0) && (newstop<Bid-_marketStopLevel*Point))
            {
            if (!OrderModify(ticketId,_orderOpenPrice,newstop,OrderTakeProfit(),OrderExpiration()))
            Print("Не удалось модифицировать ордер №",OrderTicket(),". Ошибка: ",GetLastError());
            }
         // иначе тралим только если новый стоп лучше старого
         else
            {
            if ((newstop>_orderSL) && (newstop<Bid-_marketStopLevel*Point))
            if (!OrderModify(ticketId,_orderOpenPrice,newstop,OrderTakeProfit(),OrderExpiration()))
            Print("Не удалось модифицировать ордер №",OrderTicket(),". Ошибка: ",GetLastError());
            }
         }
      else
         {
         // если стоплосс неопределен, то тралим, если стоп лучше открытия
         if ((_orderSL==0) && (newstop>_orderOpenPrice) && (newstop<Bid-_marketStopLevel*Point))
            {
            if (!OrderModify(ticketId,_orderOpenPrice,newstop,OrderTakeProfit(),OrderExpiration()))
            Print("Не удалось модифицировать ордер №",OrderTicket(),". Ошибка: ",GetLastError());
            }
         // если стоп не равен 0, то меняем его, если он лучше предыдущего и курса открытия
         else
            {
            if ((newstop>_orderSL) && (newstop>_orderOpenPrice) && (newstop<Bid-_marketStopLevel*Point))
            if (!OrderModify(ticketId,_orderOpenPrice,newstop,OrderTakeProfit(),OrderExpiration()))
            Print("Не удалось модифицировать ордер №",OrderTicket(),". Ошибка: ",GetLastError());
            }
         }
      }
      
   // если короткая позиция (OP_SELL)
   if (_orderType==OP_SELL)
      {
      // откладываем от текущего курса (новый стоплосс)
      newstop = Ask + atrXcoeff;
      
      // если trailingInLoss==true (т.е. следует тралить в зоне лоссов), то
      if (trailingInLoss==true)      
         {
         // если стоплосс неопределен, то тралим в любом случае
         if ((_orderSL==0) && (newstop>Ask+_marketStopLevel*Point))
            {
            if (!OrderModify(ticketId,_orderOpenPrice,newstop,OrderTakeProfit(),OrderExpiration()))
            Print("Не удалось модифицировать ордер №",OrderTicket(),". Ошибка: ",GetLastError());
            }
         // иначе тралим только если новый стоп лучше старого
         else
            {
            if ((newstop<_orderSL) && (newstop>Ask+_marketStopLevel*Point))
            if (!OrderModify(ticketId,_orderOpenPrice,newstop,OrderTakeProfit(),OrderExpiration()))
            Print("Не удалось модифицировать ордер №",OrderTicket(),". Ошибка: ",GetLastError());
            }
         }
      else
         {
         // если стоплосс неопределен, то тралим, если стоп лучше открытия
         if ((_orderSL==0) && (newstop<_orderOpenPrice) && (newstop>Ask+_marketStopLevel*Point))
            {
            if (!OrderModify(ticketId,_orderOpenPrice,newstop,OrderTakeProfit(),OrderExpiration()))
            Print("Не удалось модифицировать ордер №",OrderTicket(),". Ошибка: ",GetLastError());
            }
         // если стоп не равен 0, то меняем его, если он лучше предыдущего и курса открытия
         else
            {
            if ((newstop<_orderSL) && (newstop<_orderOpenPrice) && (newstop>Ask+_marketStopLevel*Point))
            if (!OrderModify(ticketId,_orderOpenPrice,newstop,OrderTakeProfit(),OrderExpiration()))
            Print("Не удалось модифицировать ордер №",OrderTicket(),". Ошибка: ",GetLastError());
            }
         }
      }      
   }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| ТРЕЙЛИНГ RATCHET БАРИШПОЛЬЦА                                     |
//| При достижении профитом уровня 1 стоплосс - в +1, при достижении |
//| профитом уровня 2 профита - стоплосс - на уровень 1, когда       |
//| профит достигает уровня 3 профита, стоплосс - на уровень 2       |
//| (дальше можно трейлить другими методами)                         |
//| при работе в лоссовом участке - тоже 3 уровня, но схема работы   |
//| с ними несколько иная, а именно: если мы опустились ниже уровня, |
//| а потом поднялись выше него (пример для покупки), то стоплосс    |
//| ставим на следующий, более глубокий уровень (например, уровни    |
//| -5, -10 и -25, стоплосс -40; если опустились ниже -10, а потом   |
//| поднялись выше -10, то стоплосс - на -25, если поднимемся выще   |
//| -5, то стоплосс перенесем на -10, при -2 (спрэд) стоп на -5      |
//| работаем только с одной позицией одновременно                    |
//+------------------------------------------------------------------+
void trailingRatchetB(int ticketId,int pf_level_1,int pf_level_2,int pf_level_3,int ls_level_1,int ls_level_2,int ls_level_3,bool trailingInLoss)
   {
    
   // проверяем переданные значения
   if ((ticketId==0) || (!OrderSelect(ticketId,SELECT_BY_TICKET)) || (pf_level_2<=pf_level_1) || (pf_level_3<=pf_level_2) || 
   (pf_level_3<=pf_level_1) || (pf_level_2-pf_level_1<=_marketStopLevel*Point) || (pf_level_3-pf_level_2<=_marketStopLevel*Point) ||
   (pf_level_1<=_marketStopLevel))
      {
      Print("Трейлинг функцией trailingRatchetB() невозможен из-за некорректности значений переданных ей аргументов.");
      return;
      }
                
   // если длинная позиция (OP_BUY)
   if (_orderType==OP_BUY)
      {
      double dBid = MarketInfo(_symbol,MODE_BID);
      
      // Работаем на участке профитов
      
      // если разница "текущий_курс-курс_открытия" больше чем "pf_level_3+спрэд", стоплосс переносим в "pf_level_2+спрэд"
      if ((dBid-_orderOpenPrice)>=pf_level_3*Point)
         {
         if ((_orderSL==0) || (_orderSL<_orderOpenPrice + pf_level_2 *Point))
            if(!OrderModify(ticketId,_orderOpenPrice,_orderOpenPrice + pf_level_2*Point,OrderTakeProfit(),OrderExpiration()))
               Print("Не удалось модифицировать стоплосс ордера №",OrderTicket(),". Ошибка: ",GetLastError());
         }
      else
      // если разница "текущий_курс-курс_открытия" больше чем "pf_level_2+спрэд", стоплосс переносим в "pf_level_1+спрэд"
      if ((dBid-_orderOpenPrice)>=pf_level_2*Point)
         {
         if ((_orderSL==0) || (_orderSL<_orderOpenPrice + pf_level_1*Point))
            if(!OrderModify(ticketId,_orderOpenPrice,_orderOpenPrice + pf_level_1*Point,OrderTakeProfit(),OrderExpiration()))
               Print("Не удалось модифицировать стоплосс ордера №",OrderTicket(),". Ошибка: ",GetLastError());
         }
      else        
      // если разница "текущий_курс-курс_открытия" больше чем "pf_level_1+спрэд", стоплосс переносим в +1 ("открытие + спрэд")
      if ((dBid-_orderOpenPrice)>=pf_level_1*Point)
      // если стоплосс не определен или хуже чем "открытие+1"
         {
         if ((_orderSL==0) || (_orderSL<_orderOpenPrice + 1*Point))
            if(!OrderModify(ticketId,_orderOpenPrice,_orderOpenPrice + 1*Point,OrderTakeProfit(),OrderExpiration()))
               Print("Не удалось модифицировать стоплосс ордера №",OrderTicket(),". Ошибка: ",GetLastError());
         }

      // Работаем на участке лоссов
      if (trailingInLoss==true)      
         {
         // Глобальная переменная терминала содержит значение самого уровня убытка (ls_level_n), ниже которого опускался курс
         // (если он после этого поднимается выше, устанавливаем стоплосс на ближайшем более глубоком уровне убытка (если это не начальный стоплосс позиции)
         // Создаём глобальную переменную (один раз)
         if(!GlobalVariableCheck("zeticket")) 
            {
            GlobalVariableSet("zeticket",ticketId);
            // при создании присвоим ей "0"
            GlobalVariableSet("dpstlslvl",0);
            }
         // если работаем с новой сделкой (новый тикет), затираем значение dpstlslvl
         if (GlobalVariableGet("zeticket")!=ticketId)
            {
            GlobalVariableSet("dpstlslvl",0);
            GlobalVariableSet("zeticket",ticketId);
            }
      
         // убыточным считаем участок ниже курса открытия и до первого уровня профита
         if ((dBid-_orderOpenPrice)<pf_level_1*Point)         
            {
            // если (текущий_курс лучше/равно открытие) и (dpstlslvl>=ls_level_1), стоплосс - на ls_level_1
            if (dBid>=_orderOpenPrice) 
            if ((_orderSL==0) || (_orderSL<(_orderOpenPrice-ls_level_1*Point)))
               if(!OrderModify(ticketId,_orderOpenPrice,_orderOpenPrice-ls_level_1*Point,OrderTakeProfit(),OrderExpiration()))
                  Print("Не удалось модифицировать стоплосс ордера №",OrderTicket(),". Ошибка: ",GetLastError());
      
            // если (текущий_курс лучше уровня_убытка_1) и (dpstlslvl>=ls_level_1), стоплосс - на ls_level_2
            if ((dBid>=_orderOpenPrice-ls_level_1*Point) && (GlobalVariableGet("dpstlslvl")>=ls_level_1))
            if ((_orderSL==0) || (_orderSL<(_orderOpenPrice-ls_level_2*Point)))
               if(!OrderModify(ticketId,_orderOpenPrice,_orderOpenPrice-ls_level_2*Point,OrderTakeProfit(),OrderExpiration()))
                  Print("Не удалось модифицировать стоплосс ордера №",OrderTicket(),". Ошибка: ",GetLastError());
      
            // если (текущий_курс лучше уровня_убытка_2) и (dpstlslvl>=ls_level_2), стоплосс - на ls_level_3
            if ((dBid>=_orderOpenPrice-ls_level_2*Point) && (GlobalVariableGet("dpstlslvl")>=ls_level_2))
            if ((_orderSL==0) || (_orderSL<(_orderOpenPrice-ls_level_3*Point)))
               if(!OrderModify(ticketId,_orderOpenPrice,_orderOpenPrice-ls_level_3*Point,OrderTakeProfit(),OrderExpiration()))
                  Print("Не удалось модифицировать стоплосс ордера №",OrderTicket(),". Ошибка: ",GetLastError());
      
            // проверим/обновим значение наиболее глубокой "взятой" лоссовой "ступеньки"
            // если "текущий_курс-курс открытия+спрэд" меньше 0, 
            if ((dBid-_orderOpenPrice+_marketSpread*Point)<0)
            // проверим, не меньше ли он того или иного уровня убытка
               {
               if (dBid<=_orderOpenPrice-ls_level_3*Point)
               if (GlobalVariableGet("dpstlslvl")<ls_level_3)
               GlobalVariableSet("dpstlslvl",ls_level_3);
               else
               if (dBid<=_orderOpenPrice-ls_level_2*Point)
               if (GlobalVariableGet("dpstlslvl")<ls_level_2)
               GlobalVariableSet("dpstlslvl",ls_level_2);   
               else
               if (dBid<=_orderOpenPrice-ls_level_1*Point)
               if (GlobalVariableGet("dpstlslvl")<ls_level_1)
               GlobalVariableSet("dpstlslvl",ls_level_1);
               }
            } // end of "if ((dBid-_orderOpenPrice)<pf_level_1*Point)"
         } // end of "if (trailingInLoss==true)"
      }
      
   // если короткая позиция (OP_SELL)
   if (_orderType==OP_SELL)
      {
      double dAsk = MarketInfo(_symbol,MODE_ASK);
      
      // Работаем на участке профитов
      
      // если разница "текущий_курс-курс_открытия" больше чем "pf_level_3+спрэд", стоплосс переносим в "pf_level_2+спрэд"
      if ((_orderOpenPrice-dAsk)>=pf_level_3*Point)
         {
         if ((_orderSL==0) || (_orderSL>_orderOpenPrice - (pf_level_2 + _marketSpread)*Point))
            if(!OrderModify(ticketId,_orderOpenPrice,_orderOpenPrice - (pf_level_2 + _marketSpread)*Point,OrderTakeProfit(),OrderExpiration()))
               Print("Не удалось модифицировать стоплосс ордера №",OrderTicket(),". Ошибка: ",GetLastError());
         }
      else
      // если разница "текущий_курс-курс_открытия" больше чем "pf_level_2+спрэд", стоплосс переносим в "pf_level_1+спрэд"
      if ((_orderOpenPrice-dAsk)>=pf_level_2*Point)
         {
         if ((_orderSL==0) || (_orderSL>_orderOpenPrice - (pf_level_1 + _marketSpread)*Point))
            if(!OrderModify(ticketId,_orderOpenPrice,_orderOpenPrice - (pf_level_1 + _marketSpread)*Point,OrderTakeProfit(),OrderExpiration()))
               Print("Не удалось модифицировать стоплосс ордера №",OrderTicket(),". Ошибка: ",GetLastError());
         }
      else        
      // если разница "текущий_курс-курс_открытия" больше чем "pf_level_1+спрэд", стоплосс переносим в +1 ("открытие + спрэд")
      if ((_orderOpenPrice-dAsk)>=pf_level_1*Point)
      // если стоплосс не определен или хуже чем "открытие+1"
         {
         if ((_orderSL==0) || (_orderSL>_orderOpenPrice - (1 + _marketSpread)*Point))
            if(!OrderModify(ticketId,_orderOpenPrice,_orderOpenPrice - (1 + _marketSpread)*Point,OrderTakeProfit(),OrderExpiration()))
               Print("Не удалось модифицировать стоплосс ордера №",OrderTicket(),". Ошибка: ",GetLastError());
         }

      // Работаем на участке лоссов
      if (trailingInLoss==true)      
         {
         // Глобальная переменная терминала содержит значение самого уровня убытка (ls_level_n), ниже которого опускался курс
         // (если он после этого поднимается выше, устанавливаем стоплосс на ближайшем более глубоком уровне убытка (если это не начальный стоплосс позиции)
         // Создаём глобальную переменную (один раз)
         if(!GlobalVariableCheck("zeticket")) 
            {
            GlobalVariableSet("zeticket",ticketId);
            // при создании присвоим ей "0"
            GlobalVariableSet("dpstlslvl",0);
            }
         // если работаем с новой сделкой (новый тикет), затираем значение dpstlslvl
         if (GlobalVariableGet("zeticket")!=ticketId)
            {
            GlobalVariableSet("dpstlslvl",0);
            GlobalVariableSet("zeticket",ticketId);
            }
      
         // убыточным считаем участок ниже курса открытия и до первого уровня профита
         if ((_orderOpenPrice-dAsk)<pf_level_1*Point)         
            {
            // если (текущий_курс лучше/равно открытие) и (dpstlslvl>=ls_level_1), стоплосс - на ls_level_1
            if (dAsk<=_orderOpenPrice) 
            if ((_orderSL==0) || (_orderSL>(_orderOpenPrice + (ls_level_1 + _marketSpread)*Point)))
               if(!OrderModify(ticketId,_orderOpenPrice,_orderOpenPrice + (ls_level_1 + _marketSpread)*Point,OrderTakeProfit(),OrderExpiration()))
                  Print("Не удалось модифицировать стоплосс ордера №",OrderTicket(),". Ошибка: ",GetLastError());
      
            // если (текущий_курс лучше уровня_убытка_1) и (dpstlslvl>=ls_level_1), стоплосс - на ls_level_2
            if ((dAsk<=_orderOpenPrice + (ls_level_1 + _marketSpread)*Point) && (GlobalVariableGet("dpstlslvl")>=ls_level_1))
            if ((_orderSL==0) || (_orderSL>(_orderOpenPrice + (ls_level_2 + _marketSpread)*Point)))
               if(!OrderModify(ticketId,_orderOpenPrice,_orderOpenPrice + (ls_level_2 + _marketSpread)*Point,OrderTakeProfit(),OrderExpiration()))
                  Print("Не удалось модифицировать стоплосс ордера №",OrderTicket(),". Ошибка: ",GetLastError());
      
            // если (текущий_курс лучше уровня_убытка_2) и (dpstlslvl>=ls_level_2), стоплосс - на ls_level_3
            if ((dAsk<=_orderOpenPrice + (ls_level_2 + _marketSpread)*Point) && (GlobalVariableGet("dpstlslvl")>=ls_level_2))
            if ((_orderSL==0) || (_orderSL>(_orderOpenPrice + (ls_level_3 + _marketSpread)*Point)))
               if(!OrderModify(ticketId,_orderOpenPrice,_orderOpenPrice + (ls_level_3 + _marketSpread)*Point,OrderTakeProfit(),OrderExpiration()))
                  Print("Не удалось модифицировать стоплосс ордера №",OrderTicket(),". Ошибка: ",GetLastError());
      
            // проверим/обновим значение наиболее глубокой "взятой" лоссовой "ступеньки"
            // если "текущий_курс-курс открытия+спрэд" меньше 0, 
            if ((_orderOpenPrice-dAsk+_marketSpread*Point)<0)
            // проверим, не меньше ли он того или иного уровня убытка
               {
               if (dAsk>=_orderOpenPrice+(ls_level_3+_marketSpread)*Point)
               if (GlobalVariableGet("dpstlslvl")<ls_level_3)
               GlobalVariableSet("dpstlslvl",ls_level_3);
               else
               if (dAsk>=_orderOpenPrice+(ls_level_2+_marketSpread)*Point)
               if (GlobalVariableGet("dpstlslvl")<ls_level_2)
               GlobalVariableSet("dpstlslvl",ls_level_2);   
               else
               if (dAsk>=_orderOpenPrice+(ls_level_1+_marketSpread)*Point)
               if (GlobalVariableGet("dpstlslvl")<ls_level_1)
               GlobalVariableSet("dpstlslvl",ls_level_1);
               }
            } // end of "if ((dBid-_orderOpenPrice)<pf_level_1*Point)"
         } // end of "if (trailingInLoss==true)"
      }      
   }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| ТРЕЙЛИНГ ПО ЦЕНВОМУ КАНАЛУ                                       |
//| Функции передаётся тикет позиции, период (кол-во баров) для      | 
//| рассчета верхней и нижней границ канала, отступ (пунктов), на    |
//| котором размещается стоплосс от границы канала                   |
//| Трейлинг по закрывшимся барам.                                   |
//+------------------------------------------------------------------+
void trailingByPriceChannel(int iTicket, int _period,int iBars,int iIndent)
   {     
   
   // проверяем переданные значения
   if (!IsTimeFrameValid(_period) || (iBars<1) || (iIndent<0) || (iTicket==0) || (!OrderSelect(iTicket,SELECT_BY_TICKET)))
      {
      Print("Трейлинг функцией trailingByPriceChannel() невозможен из-за некорректности значений переданных ей аргументов.");
      return;
      } 
   
   double   dChnl_max; // верхняя граница канала
   double   dChnl_min; // нижняя граница канала
   
   // определяем макс.хай и мин.лоу за iBars баров начиная с [1] (= верхняя и нижняя границы ценового канала)
   dChnl_max = High[iHighest(_symbol,_period,2,iBars,1)] + (iIndent+_marketSpread)*Point;
   dChnl_min = Low[iLowest(_symbol,_period,1,iBars,1)] - iIndent*Point;   
   
   // если длинная позиция, и её стоплосс хуже (ниже нижней границы канала либо не определен, ==0), модифицируем его
   if (_orderType==OP_BUY)
      {
      if ((_orderSL<dChnl_min) && (dChnl_min<Bid-_marketStopLevel*Point))
         {
         if (!OrderModify(iTicket,_orderOpenPrice,dChnl_min,OrderTakeProfit(),OrderExpiration()))
         Print("Не удалось модифицировать стоплосс ордера №",OrderTicket(),". Ошибка: ",GetLastError());
         }
      }
   
   // если позиция - короткая, и её стоплосс хуже (выше верхней границы канала или не определён, ==0), модифицируем его
   if (_orderType==OP_SELL)
      {
      if (((_orderSL==0) || (_orderSL>dChnl_max)) && (dChnl_min>Ask+_marketStopLevel*Point))
         {
         if (!OrderModify(iTicket,_orderOpenPrice,dChnl_max,OrderTakeProfit(),OrderExpiration()))
         Print("Не удалось модифицировать стоплосс ордера №",OrderTicket(),". Ошибка: ",GetLastError());
         }
      }
   }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| ТРЕЙЛИНГ ПО СКОЛЬЗЯЩЕМУ СРЕДНЕМУ                                 |
//| Функции передаётся тикет позиции и параметры средней (таймфрейм, | 
//| период, тип, сдвиг относительно графика, метод сглаживания,      |
//| составляющая OHCL для построения, № бара, на котором берется     |
//| значение средней.                                                |
//+------------------------------------------------------------------+

//    Допустимые варианты ввода:   
//    iTmFrme:    1 (M1), 5 (M5), 15 (M15), 30 (M30), 60 (H1), 240 (H4), 1440 (D), 10080 (W), 43200 (MN);
//    iMAPeriod:  2-infinity, целые числа; 
//    iMAShift:   целые положительные или отрицательные числа, а также 0;
//    MAMethod:   0 (MODE_SMA), 1 (MODE_EMA), 2 (MODE_SMMA), 3 (MODE_LWMA);
//    iApplPrice: 0 (PRICE_CLOSE), 1 (PRICE_OPEN), 2 (PRICE_HIGH), 3 (PRICE_LOW), 4 (PRICE_MEDIAN), 5 (PRICE_TYPICAL), 6 (PRICE_WEIGHTED)
//    iShift:     0-Bars, целые числа;
//    iIndent:    0-infinity, целые числа;

void trailingByMA(int iTicket,int iTmFrme,int iMAPeriod,int iMAShift,int MAMethod,int iApplPrice,int iShift,int iIndent)
   {     
   
   // проверяем переданные значения
   if ((iTicket==0) || (!OrderSelect(iTicket,SELECT_BY_TICKET)) || ((iTmFrme!=1) && (iTmFrme!=5) && (iTmFrme!=15) && (iTmFrme!=30) && (iTmFrme!=60) && (iTmFrme!=240) && (iTmFrme!=1440) && (iTmFrme!=10080) && (iTmFrme!=43200)) ||
   (iMAPeriod<2) || (MAMethod<0) || (MAMethod>3) || (iApplPrice<0) || (iApplPrice>6) || (iShift<0) || (iIndent<0))
      {
      Print("Трейлинг функцией trailingByMA() невозможен из-за некорректности значений переданных ей аргументов.");
      return;
      } 

   double   dMA; // значение скользящего среднего с переданными параметрами
   
   // определим значение МА с переданными функции параметрами
   dMA = iMA(_symbol,iTmFrme,iMAPeriod,iMAShift,MAMethod,iApplPrice,iShift);
         
   // если длинная позиция, и её стоплосс хуже значения среднего с отступом в iIndent пунктов, модифицируем его
   if (_orderType==OP_BUY)
      {
      if ((_orderSL<dMA-iIndent*Point) && (dMA-iIndent*Point<Bid-_marketStopLevel*Point))
         {
         if (!OrderModify(iTicket,_orderOpenPrice,dMA-iIndent*Point,OrderTakeProfit(),OrderExpiration()))
         Print("Не удалось модифицировать стоплосс ордера №",OrderTicket(),". Ошибка: ",GetLastError());
         }
      }
   
   // если позиция - короткая, и её стоплосс хуже (выше верхней границы канала или не определён, ==0), модифицируем его
   if (_orderType==OP_SELL)
      {
      if (((_orderSL==0) || (_orderSL>dMA+(_marketSpread+iIndent)*Point)) && (dMA+(_marketSpread+iIndent)*Point>Ask+_marketStopLevel*Point))
         {
         if (!OrderModify(iTicket,_orderOpenPrice,dMA+(_marketSpread+iIndent)*Point,OrderTakeProfit(),OrderExpiration()))
         Print("Не удалось модифицировать стоплосс ордера №",OrderTicket(),". Ошибка: ",GetLastError());
         }
      }
   }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| ТРЕЙЛИНГ "ПОЛОВИНЯЩИЙ"                                           |
//| По закрытии очередного периода (бара) подтягиваем стоплосс на    |
//| половину (но можно и любой иной коэффициент) дистанции, прой-    |
//| денной курсом (т.е., например, по закрытии суток профит +55 п. - |
//| стоплосс переносим в 55/2=27 п. Если по закрытии след.           |
//| суток профит достиг, допустим, +80 п., то стоплосс переносим на  |
//| половину (напр.) расстояния между тек. стоплоссом и курсом на    |
//| закрытии бара - 27 + (80-27)/2 = 27 + 53/2 = 27 + 26 = 53 п.     |
//| iTicket - тикет позиции; iTmFrme - таймфрейм (в минутах, цифрами |
//| dCoeff - "коэффициент поджатия", в % от 0.01 до 1 (в последнем   |
//| случае стоплосс будет перенесен (если получится) вплотную к тек. |
//| курсу и позиция, скорее всего, сразу же закроется)               |
//| bTrlinloss - стоит ли тралить на лоссовом участке - если да, то  |
//| по закрытию очередного бара расстояние между стоплоссом (в т.ч.  |
//| "до" безубытка) и текущим курсом будет сокращаться в dCoeff раз  |
//| чтобы посл. вариант работал, обязательно должен быть определён   |
//| стоплосс (не равен 0)                                            |
//+------------------------------------------------------------------+

void trailingFiftyFifty(int iTicket,int iTmFrme,double dCoeff,bool bTrlinloss)
   { 
   // активируем трейлинг только по закрытии бара
   if (sdtPrevtime == iTime(_symbol,iTmFrme,0)) return;
   else
      {
      sdtPrevtime = iTime(_symbol,iTmFrme,0);             
      
      // проверяем переданные значения
      if ((iTicket==0) || (!OrderSelect(iTicket,SELECT_BY_TICKET)) || 
      ((iTmFrme!=1) && (iTmFrme!=5) && (iTmFrme!=15) && (iTmFrme!=30) && (iTmFrme!=60) && (iTmFrme!=240) && 
      (iTmFrme!=1440) && (iTmFrme!=10080) && (iTmFrme!=43200)) || (dCoeff<0.01) || (dCoeff>1.0))
         {
         Print("Трейлинг функцией trailingFiftyFifty() невозможен из-за некорректности значений переданных ей аргументов.");
         return;
         }
         
      // начинаем тралить - с первого бара после открывающего (иначе при bTrlinloss сразу же после открытия 
      // позиции стоплосс будет перенесен на половину расстояния между стоплоссом и курсом открытия)
      // т.е. работаем только при условии, что с момента OrderOpenTime() прошло не менее iTmFrme минут
      if (iTime(_symbol,iTmFrme,0)>OrderOpenTime())
      {         
      
      double dBid = MarketInfo(_symbol,MODE_BID);
      double dAsk = MarketInfo(_symbol,MODE_ASK);
      double dNewSl = 0.0;
      double dNexMove = 0.0;     
      
      // для длинной позиции переносим стоплосс на dCoeff дистанции от курса открытия до Bid на момент открытия бара
      // (если такой стоплосс лучше имеющегося и изменяет стоплосс в сторону профита)
      if (_orderType==OP_BUY)
         {
         if ((bTrlinloss) && (_orderSL!=0))
            {
            dNexMove = NormalizeDouble(dCoeff*(dBid-_orderSL),Digits);
            dNewSl = NormalizeDouble(_orderSL+dNexMove,Digits);            
            }
         else
            {
            // если стоплосс ниже курса открытия, то тралим "от курса открытия"
            if (_orderOpenPrice>_orderSL)
               {
               dNexMove = NormalizeDouble(dCoeff*(dBid-_orderOpenPrice),Digits);                 
               //Print("dNexMove = ",dCoeff,"*(",dBid,"-",_orderOpenPrice,")");
               dNewSl = NormalizeDouble(_orderOpenPrice+dNexMove,Digits);
               //Print("dNewSl = ",_orderOpenPrice,"+",dNexMove);
               }
         
            // если стоплосс выше курса открытия, тралим от стоплосса
            if (_orderSL>=_orderOpenPrice)
               {
               dNexMove = NormalizeDouble(dCoeff*(dBid-_orderSL),Digits);
               dNewSl = NormalizeDouble(_orderSL+dNexMove,Digits);
               }                                      
            }
            
         // стоплосс перемещаем только в случае, если новый стоплосс лучше текущего и если смещение - в сторону профита
         // (при первом поджатии, от курса открытия, новый стоплосс может быть лучше имеющегося, и в то же время ниже 
         // курса открытия (если dBid ниже последнего) 
         if ((dNewSl>_orderSL) && (dNexMove>0) && ((dNewSl<Bid- _marketStopLevel*Point)))
            {
            if (!OrderModify(OrderTicket(),_orderOpenPrice,dNewSl,OrderTakeProfit(),OrderExpiration(),Red))
            Print("Не удалось модифицировать стоплосс ордера №",OrderTicket(),". Ошибка: ",GetLastError());
            }
         }       
      
      // действия для короткой позиции   
      if (_orderType==OP_SELL)
         {
         if ((bTrlinloss) && (_orderSL!=0))
            {
            dNexMove = NormalizeDouble(dCoeff*(_orderSL-(dAsk+_marketSpread*Point)),Digits);
            dNewSl = NormalizeDouble(_orderSL-dNexMove,Digits);            
            }
         else
            {         
            // если стоплосс выше курса открытия, то тралим "от курса открытия"
            if (_orderOpenPrice<_orderSL)
               {
               dNexMove = NormalizeDouble(dCoeff*(_orderOpenPrice-(dAsk+_marketSpread*Point)),Digits);                 
               dNewSl = NormalizeDouble(_orderOpenPrice-dNexMove,Digits);
               }
         
            // если стоплосс нижу курса открытия, тралим от стоплосса
            if (_orderSL<=_orderOpenPrice)
               {
               dNexMove = NormalizeDouble(dCoeff*(_orderSL-(dAsk+_marketSpread*Point)),Digits);
               dNewSl = NormalizeDouble(_orderSL-dNexMove,Digits);
               }                  
            }
         
         // стоплосс перемещаем только в случае, если новый стоплосс лучше текущего и если смещение - в сторону профита
         if ((dNewSl<_orderSL) && (dNexMove>0) && (dNewSl>Ask+_marketStopLevel*Point))
            {
            if (!OrderModify(OrderTicket(),_orderOpenPrice,dNewSl,OrderTakeProfit(),OrderExpiration(),Blue))
            Print("Не удалось модифицировать стоплосс ордера №",OrderTicket(),". Ошибка: ",GetLastError());
            }
         }               
      }
      }   
   }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| ТРЕЙЛИНГ KillLoss                                                |
//| Применяется на участке лоссов. Суть: стоплосс движется навстречу |
//| курсу со скоростью движения курса х коэффициент (dSpeedCoeff).   |
//| При этом коэффициент можно "привязать" к скорости увеличения     |
//| убытка - так, чтобы при быстром росте лосса потерять меньше. При |
//| коэффициенте = 1 стоплосс сработает ровно посредине между уров-  |
//| нем стоплосса и курсом на момент запуска функции, при коэфф.>1   |
//| точка встречи курса и стоплосса будет смещена в сторону исход-   |
//| ного положения курса, при коэфф.<1 - наоборот, ближе к исходно-  |
//| му стоплоссу.                                                    |
//+------------------------------------------------------------------+

void KillLoss(int iTicket,double dSpeedCoeff)
   {   
   // проверяем переданные значения
   if ((iTicket==0) || (!OrderSelect(iTicket,SELECT_BY_TICKET)) || (dSpeedCoeff<0.1))
      {
      Print("Трейлинг функцией KillLoss() невозможен из-за некорректности значений переданных ей аргументов.");
      return;
      }           
      
   double dStopPriceDiff = 0.0; // расстояние (пунктов) между курсом и стоплоссом   
   double dToMove; // кол-во пунктов, на которое следует переместить стоплосс   
   // текущий курс
   double dBid = MarketInfo(Order_symbol,MODE_BID);
   double dAsk = MarketInfo(Order_symbol,MODE_ASK);      
   
   // текущее расстояние между курсом и стоплоссом
   if (_orderType==OP_BUY) dStopPriceDiff = dBid - _orderSL;
   if (_orderType==OP_SELL) dStopPriceDiff = (_orderSL + MarketInfo(Order_symbol,MODE_SPREAD)*MarketInfo(Order_symbol,MODE_POINT)) - dAsk;                  
   
   // проверяем, если тикет != тикету, с которым работали раньше, запоминаем текущее расстояние между курсом и стоплоссом
   if (GlobalVariableGet("zeticket")!=iTicket)
      {
      GlobalVariableSet("sldiff",dStopPriceDiff);      
      GlobalVariableSet("zeticket",iTicket);
      }
   else
      {                                   
      // итак, у нас есть коэффициент ускорения изменения курса
      // на каждый пункт, который проходит курс в сторону лосса, 
      // мы должны переместить стоплосс ему на встречу на dSpeedCoeff раз пунктов
      // (например, если лосс увеличился на 3 пункта за тик, dSpeedCoeff = 1.5, то
      // стоплосс подтягиваем на 3 х 1.5 = 4.5, округляем - 5 п. Если подтянуть не 
      // удаётся (слишком близко), ничего не делаем.            
      
      // кол-во пунктов, на которое приблизился курс к стоплоссу с момента предыдущей проверки (тика, по идее)
      dToMove = (GlobalVariableGet("sldiff") - dStopPriceDiff) / MarketInfo(Order_symbol,MODE_POINT);
      
      // записываем новое значение, но только если оно уменьшилось
      if (dStopPriceDiff<GlobalVariableGet("sldiff"))
      GlobalVariableSet("sldiff",dStopPriceDiff);
      
      // дальше действия на случай, если расстояние уменьшилось (т.е. курс приблизился к стоплоссу, убыток растет)
      if (dToMove>0)
         {       
         // стоплосс, соответственно, нужно также передвинуть на такое же расстояние, но с учетом коэфф. ускорения
         dToMove = MathRound(dToMove * dSpeedCoeff) * MarketInfo(Order_symbol,MODE_POINT);                 
      
         // теперь проверим, можем ли мы подтянуть стоплосс на такое расстояние
         if (_orderType==OP_BUY)
            {
            if (dBid - (_orderSL + dToMove)>MarketInfo(Order_symbol,MODE_STOPLEVEL)* MarketInfo(Order_symbol,MODE_POINT))
               if(!OrderModify(iTicket,_orderOpenPrice,_orderSL + dToMove,OrderTakeProfit(),OrderExpiration()))
                  Print("Не удалось модифицировать стоплосс ордера №",OrderTicket(),". Ошибка: ",GetLastError());
            }
         if (_orderType==OP_SELL)
            {
            if ((_orderSL - dToMove) - dAsk>MarketInfo(Order_symbol,MODE_STOPLEVEL) * MarketInfo(Order_symbol,MODE_POINT))
               if(OrderModify(iTicket,_orderOpenPrice,_orderSL - dToMove,OrderTakeProfit(),OrderExpiration()))
                  Print("Не удалось модифицировать стоплосс ордера №",OrderTicket(),". Ошибка: ",GetLastError());
            }      
         }
      }            
   }
   
//+------------------------------------------------------------------+ 