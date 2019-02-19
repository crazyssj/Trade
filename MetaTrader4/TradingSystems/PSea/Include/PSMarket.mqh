//+------------------------------------------------------------------+
//|                                                     PSMarket.mqh |
//|                                   Copyright 2019, PSInvest Corp. |
//|                                          https://www.psinvest.eu |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, PSInvest Corp."
#property link      "https://www.psinvest.eu"
#property version   "1.00"
#property library
#property strict

#include <FileLog.mqh>
#include <stdlib.mqh>

#define TimeFrameCount 9
#define UsedSymbolCount 9

int TimeFrames[TimeFrameCount] = { PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_M30, PERIOD_H1, PERIOD_H4, PERIOD_D1, PERIOD_W1, PERIOD_MN1 };
string UsedSymbols[UsedSymbolCount] = { "EURUSD", "USDJPY", "GBPUSD", "USDCHF", "USDCAD", "AUDUSD", "NZDUSD" };

const int OP_NONE = -1;


CFileLog* MarketFileLog;

bool IsSymbolValid(string symbol)
{
   return GetSymbolIndex(symbol) > -1;
}

int GetSymbolIndex(string symbol)
{
   for(int i = 0; i < UsedSymbolCount; i++)
   {
      
      if (UsedSymbols[i] == symbol) 
      {
         return i;
      }
   }

   return -1;
}

bool IsTimeFrameValid(int period)
{
   return GetTimeFrameIndex(period) > -1;
}

// @brief Get Time frame index.
// @param period: time frame period.
// @return int -1 can not get previous period
//   Example: period = PERIOD_M1, result: 0.
int GetTimeFrameIndex(int period)
{
   for(int i = 0; i < TimeFrameCount; i++)
   {
      
      if (TimeFrames[i] == period) 
      {
         return i;
      }
   }

   return -1;
}

// @brief Get previous TF.
//   If period = PERIOD_H1, result: PERIOD_M30.
// @param period: finded period from which gets previos.
// @paramperiodDown: it should be form 1 to 8;
// @return int -1 can not get previous period
int GetPreviousTimeFrame(int period, short periodDown = 1)
{
   int tf = GetTimeFrameIndex(period);
   if (tf == -1) {
      return -1;
   }
   
   int newTFPeriod = tf - periodDown;
   // Check if first period found or previous period lover than 0.
   if (tf == 0 || (newTFPeriod < 0)) {
      return -1;
   }
   
   return TimeFrames[newTFPeriod];
}

// @brief Get next TF.
//   If period = PERIOD_H1, result: PERIOD_H4.
// @param period: finded period from which gets next.
// @paramperiodDown: it should be form 0 to 7;
// @return int -1 can not get next period
int GetNextTimeFrame(int period, short periodDown = 1)
{
   int tf = GetTimeFrameIndex(period);
   if (tf == -1) {
      return -1;
   }
   
   int newTFPeriod = tf + periodDown;
   // Check is greater than TF count.
   if (newTFPeriod >= TimeFrameCount) {
      return -1;
   }
   
   return TimeFrames[newTFPeriod];
}

bool CloseOrder(int ticketId, double lot, int orderType, int slippage)
{
   double price = orderType == OP_BUY ? Bid /*Buy*/ : Ask /*Sell*/;

   bool result = OrderClose(ticketId, lot, price, slippage, orderType == OP_BUY ? clrBlue : clrRed);

   if(!result)
   {
      int error = GetLastError();

      MarketFileLog.Error(StringConcatenate("Failed to Close ", orderType ? "Buy" : "Sell", " order #", OrderTicket(), ". Error code = ",
            error,", ",ErrorDescription(error), "!"));
   }
   
   return result;
}

bool CloseOrder(int ticketId, int slippage)
{
   if (!GetOrderByTicket(ticketId))
      return false;
   
   int orderType = OrderType();

   return CloseOrder(ticketId, OrderLots(), slippage, orderType);
}

bool CloseOrders(string symbol, int magicNumber, int slippage, int orderType = -1)
{
   int ordersTotal = OrdersTotal();
   bool result = true;

   if (orderType == OP_NONE) 
   {
      // Closing all.
      for(int i = 0; i < ordersTotal; i++)
      {
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if(OrderSymbol() == symbol && OrderMagicNumber() == magicNumber)
            {
               result &= CloseOrder(OrderTicket(), OrderLots(), OrderType(), slippage);
            }
         }
      }
   }
   else
   {
      // Closing depend order type.
      for(int i = 0; i < ordersTotal; i++)
      {
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if(OrderSymbol() == symbol && OrderMagicNumber() == magicNumber && OrderType() == orderType)
            {
               result &= CloseOrder(OrderTicket(), OrderLots(), OrderType(), slippage);
            }
         }
      }
   }
   
   return result;
}


// Finding opened order.
//  If open order is found return order ticket.
//  if none orders return -1.
int GetFirstOpenOrder(string symbol, int magicNumber)
 {
   int ordersTotal = OrdersTotal();
   
   for(int i = 0; i < ordersTotal; i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if((OrderSymbol() == symbol) && OrderMagicNumber() == magicNumber)
         {
            return(OrderTicket());
         }
      }
   }
   
   return -1;
}

int GetOpenedOrderCount(string symbol, int magicNumber)
 {
   int ordersTotal = OrdersTotal();
   int result = 0;

   for(int i = 0; i < ordersTotal; i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if((OrderSymbol() == symbol) && OrderMagicNumber() == magicNumber)
         {
            result++;
         }
      }
   }
   
   return result;
}

bool GetOrderByTicket(int ticketId)
{
   return OrderSelect(ticketId, SELECT_BY_TICKET);
}

int GetSpread(string symbol)
{
// // https://docs.mql4.com/marketinformation/symbolinfodouble   
// //--- obtain spread from the symbol properties
//    bool spreadfloat=SymbolInfoInteger(Symbol(),SYMBOL_SPREAD_FLOAT);
//    string comm=StringFormat("Spread %s = %I64d points\r\n",
//                             spreadfloat?"floating":"fixed",
//                             SymbolInfoInteger(Symbol(),SYMBOL_SPREAD));
// //--- now let's calculate the spread by ourselves
//    double ask=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
//    double bid=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//    double spread=ask-bid;
//    int spread_points=(int)MathRound(spread/SymbolInfoDouble(Symbol(),SYMBOL_POINT));
//    comm=comm+"Calculated spread = "+(string)spread_points+" points";
//    Comment(comm);   
   return (int)SymbolInfoInteger(symbol, SYMBOL_SPREAD);
}

double GetSpreadPoints()
{
   double spread = Ask - Bid;

   // If the spread is too small return 15 points.
   if (spread <= 0) {
      spread = 15 * Point;
   }
   
   return NormalizeDouble(spread, Digits);
}

/*
double Lots(int risk)
  {
   double lot=MathCeil(AccountFreeMargin()*risk/1000)/100;
   if(lot<MarketInfo(Symbol(),MODE_MINLOT))
      lot=MarketInfo(Symbol(),MODE_MINLOT);
   if(lot>MarketInfo(Symbol(),MODE_MAXLOT))
      lot=MarketInfo(Symbol(),MODE_MAXLOT);

   return(lot);
  }
*/
/*  
bool GetNecessaryLotsWithRisk(int riskPercent, double sl, double price, double& lots)
{
   //error = LOTS_NORMAL;
   
   double ticks = MathAbs(sl - price) / MarketInfo(Symbol(), MODE_TICKSIZE),  // количество тиков от старта до стопа
      riskAmount = AccountBalance() * riskPercent / 100.0;                    // максимальный убыток от сделки
   lots = riskAmount / (ticks * MarketInfo(Symbol(), MODE_TICKVALUE));     // высчитанное количество лотов
   
   double maxLot = MarketInfo(Symbol(), MODE_MAXLOT),
      minLot = MarketInfo(Symbol(), MODE_MINLOT),
      lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
      
   // проверяем допустимость лотов
   if (lots > maxLot)
   {
      //error = LOTS_TOO_BIG;
      lots = 0;
      return(false);
   }
   if (lots < minLot)
   {
      //error = LOTS_TOO_SMALL;
      lots = 0;
      return(false);
   }
   
   // округляем лоты до нужной величины
   int digits;
   if (lotStep >= 1) digits = 0;             // 1
   else  if (lotStep * 10 >= 1) digits = 1;  // 0.1
         else digits = 2;                    // 0.01
   lots = NormalizeDouble(lots, digits);

      return(true);
}
*/
/*
int _Ticket = 0, _Type = 0; double _Lots = 0.0, _OpenPrice = 0.0, _StopLoss = 0.0; 
double _TakeProfit = 0.0; datetime _OpenTime = -1; double _Profit = 0.0, _Swap = 0.0; 
double _Commission = 0.0; string _Comment = ""; datetime _Expiration = -1; 

void OneOrderInit( int magic ) 
{ 
int _GetLastError, _OrdersTotal = OrdersTotal(); 

_Ticket = 0; _Type = 0; _Lots = 0.0; _OpenPrice = 0.0; _StopLoss = 0.0; 
_TakeProfit = 0.0; _OpenTime = -1; _Profit = 0.0; _Swap = 0.0; 
_Commission = 0.0; _Comment = ""; _Expiration = -1; 

for ( int z = _OrdersTotal - 1; z >= 0; z -- ) 
{ 
if ( !OrderSelect( z, SELECT_BY_POS ) ) 
{ 
_GetLastError = GetLastError(); 
Print( "OrderSelect( ", z, ", SELECT_BY_POS ) - Error #", _GetLastError ); 
continue; 
} 
if ( OrderMagicNumber() == magic && OrderSymbol() == Symbol() ) 
{ 
_Ticket	= OrderTicket(); 
_Type	= OrderType(); 
_Lots	= NormalizeDouble( OrderLots(), 1 ); 
_OpenPrice	= NormalizeDouble( OrderOpenPrice(), Digits ); 
_StopLoss	= NormalizeDouble( OrderStopLoss(), Digits ); 
_TakeProfit	= NormalizeDouble( OrderTakeProfit(), Digits ); 
_OpenTime	= OrderOpenTime(); 
_Profit	= NormalizeDouble( OrderProfit(), 2 ); 
_Swap	= NormalizeDouble( OrderSwap(), 2 ); 
_Commission	= NormalizeDouble( OrderCommission(), 2 ); 
_Comment	= OrderComment(); 
_Expiration	= OrderExpiration(); 
return(0); 
} 
} 
} 
*/