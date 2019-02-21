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

class PSMarket
{
  	public:
		PSMarket(CFileLog *fileLog, string symbol, int period);
		~PSMarket();
      bool IsInitialised();
      int GetPreviousTimeFrame(int period, short periodDown = 1);
      int GetNextTimeFrame(int period, short periodDown = 1);
      
      bool IsSymbolValid(string symbol);
      int GetSymbolIndex(string symbol);
      
      bool IsTimeFrameValid(int period);
      int GetTimeFrameIndex(int period);
      
      bool CloseOrder(int ticketId);
      bool CloseOrder(int ticketId, double lot, int orderType);
      bool CloseOrders(int magicNumber, int orderType = -1);
      
      int GetFirstOpenOrder(int magicNumber);
      int GetOpenedOrderCount(int magicNumber);
      bool GetOrderByTicket(int ticketId);
      
      int GetSpread();
      double GetSpreadPoints();

      bool DrawVLine(const color clr, string name, const ENUM_LINE_STYLE style=STYLE_SOLID,
                     const int width = 1, const bool back = false, const bool selection = true,
                     const bool hidden = true, const long z_order = 0);
      
      double GetAtrStopLoss();
      bool OpenOrder(int operation, double lot, double stopLoss = 0, double takeProfit = 0, int magicNumber = 0);

	private:
		CFileLog *_log;
		string _symbol;
		int _period;
	   int _digits;
      int _slippage;

		bool _isInitialised;
		void CheckInputValues();
      int _vlineId;
      bool OpenOrderInt(int operation, double lot, double price, double stopLoss = 0, double takeProfit = 0, 
         string commentOrder = NULL, int magicNumber = 0, datetime expiration = 0);
      color OrderTypeToColor(int orderType, bool isOpen);
      string PSMarket::OrderTypeToString(int orderType);
      void LogError(string message);
};

PSMarket::PSMarket(CFileLog *fileLog, string symbol, int period)
{
   // slippage is usually specified as 0-3 points.
   _slippage = 3;
	_log = fileLog;
	_symbol = symbol;
	_period = period;
	_digits = Digits;

	_isInitialised = false;

	CheckInputValues();

	if (_isInitialised) 
	{

	}

   _vlineId = 1;
}

PSMarket::~PSMarket()
{
}

void PSMarket::CheckInputValues()
{
   bool log = _log != NULL;
	if (!log) {
		//_fileLog.Error(StringConcatenate(__FUNCTION__, " FileLog must not be NULL!"));
		Print(StringConcatenate(__FUNCTION__, " FileLog must not be NULL!"));
		return;
	}

	bool symbol = IsSymbolValid(_symbol);
	if (!symbol) {
		_log.Error(StringConcatenate(__FUNCTION__, " Symbol: ", _symbol, " is not valid by system!"));
	}

	bool period = IsTimeFrameValid(_period);
	if (!period) {
		_log.Error(StringConcatenate(__FUNCTION__, " Time frame: ", _period, " is not valid by system!"));
	}

   _isInitialised = log && symbol && period;

	if (!_isInitialised) 
	{
		_log.Error(StringConcatenate(__FUNCTION__, " PSMarket is not initialised!"));
	}
	else
	{
		_log.Info(StringConcatenate(__FUNCTION__, " PSMarket is initialised. Symbol: ", _symbol, ", Period (in minute): ", _period));
	}
}

bool PSMarket::IsInitialised()
{
	return _isInitialised;
}

bool PSMarket::IsSymbolValid(string symbol)
{
   return GetSymbolIndex(symbol) > -1;
}

int PSMarket::GetSymbolIndex(string symbol)
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

bool PSMarket::IsTimeFrameValid(int period)
{
   return GetTimeFrameIndex(period) > -1;
}

// @brief Get Time frame index.
// @param period: time frame period.
// @return int -1 can not get previous period
//   Example: period = PERIOD_M1, result: 0.
int PSMarket::GetTimeFrameIndex(int period)
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
int PSMarket::GetPreviousTimeFrame(int period, short periodDown = 1)
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
int PSMarket::GetNextTimeFrame(int period, short periodDown = 1)
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

bool PSMarket::CloseOrder(int ticketId, double lot, int orderType)
{
   double price = orderType == OP_BUY ? Bid /*Buy*/ : Ask /*Sell*/;

   bool result = OrderClose(ticketId, lot, price, _slippage, orderType == OP_BUY ? clrMagenta : clrLightSkyBlue);

   if(!result)
   {
      int error = GetLastError();

      _log.Error(StringConcatenate("Failed to Close ", orderType ? "Buy" : "Sell", " order #", OrderTicket(), ". Error code = ",
            error,", ",ErrorDescription(error), "!"));
   }
   
   return result;
}

bool PSMarket::CloseOrder(int ticketId)
{
   if (!GetOrderByTicket(ticketId))
      return false;
   
   int orderType = OrderType();

   return CloseOrder(ticketId, OrderLots(), orderType);
}

bool PSMarket::CloseOrders(int magicNumber, int orderType = -1)
{
   bool result = true;

   Print(StringConcatenate("ordersTotal: ", OrdersTotal()));
   // Closing depend order type.
   int i = 0;
   while(i < OrdersTotal())
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == _symbol && OrderMagicNumber() == magicNumber)
         {
            if(orderType == OP_NONE || OrderType() == orderType)
            {
               //Print(StringConcatenate("close order: #", OrderTicket()));
               if (CloseOrder(OrderTicket(), OrderLots(), OrderType())) 
               {
                  i = 0;
                  continue;
               }
               else 
               {
                  result = false;
               }
            }
         }
      }
      i++;
   }
   
   return result;
}

// Finding opened order.
//  If open order is found return order ticket.
//  if none orders return -1.
int PSMarket::GetFirstOpenOrder(int magicNumber)
 {
   int ordersTotal = OrdersTotal();
   
   for(int i = 0; i < ordersTotal; i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if((OrderSymbol() == _symbol) && OrderMagicNumber() == magicNumber)
         {
            return(OrderTicket());
         }
      }
   }
   
   return -1;
}

int PSMarket::GetOpenedOrderCount(int magicNumber)
{
   int ordersTotal = OrdersTotal();
   int result = 0;

   for(int i = 0; i < ordersTotal; i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if((OrderSymbol() == _symbol) && OrderMagicNumber() == magicNumber)
         {
            result++;
         }
      }
   }
   
   return result;
}

bool PSMarket::GetOrderByTicket(int ticketId)
{
   return OrderSelect(ticketId, SELECT_BY_TICKET);
}

int PSMarket::GetSpread()
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
   return (int)SymbolInfoInteger(_symbol, SYMBOL_SPREAD);
}

double PSMarket::GetSpreadPoints()
{
   double spread = Ask - Bid;

   // If the spread is too small return 15 points.
   if (spread <= 0) {
      spread = 15 * Point;
   }
   
   return NormalizeDouble(spread, Digits);
}

bool PSMarket::DrawVLine(const color           clr,        // line color
                 string name,
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // line style
                 const int             width=1,           // line width
                 const bool            back=false,        // in the background
                 const bool            selection=true,    // highlight to move
                 const bool            hidden=true,       // hidden in the object list
                 const long            z_order=0)         // priority for mouse click
{
    name = StringConcatenate(name, " ", _vlineId++);
    long chart_ID=0;
    
    ResetLastError();
    if(!ObjectCreate(chart_ID, name, OBJ_VLINE, 0, TimeCurrent(), 0))
    {
        Print(__FUNCTION__,
            ": failed to create a vertical line! Error code = ", GetLastError());
        return(false);
    }

    ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
    ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
    ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
    ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
    ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
    ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
    ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
    ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);

    return true;
}

double PSMarket::GetAtrStopLoss()
{
	const int atrPeriod = 14;

	double atr1 = NormalizeDouble(iATR(_symbol, _period, atrPeriod, 1), _digits);

	return atr1;
}

// @brief Open order direct on the market.
// @param operation OP_BUY or OP_SELL
// @param stopLoss in points. 0.0010
// @param takeProfit in points. 0.0010
// @param magicNumber Magic number if exist. Default 0.
// @return true if the ordder is opened, otherwise false.
bool PSMarket::OpenOrder(int operation, double lot, double stopLoss = 0, double takeProfit = 0, int magicNumber = 0)
{
   if (operation != OP_BUY && operation != OP_SELL) {
      LogError(StringConcatenate(__FUNCTION__, " unsupported order type: ", operation));
      return false;
   }

   double price = 0;
   double sl = 0;
   double tp = 0;
   if (operation == OP_BUY) 
   {
        price = Ask;
        sl = NormalizeDouble(Bid - stopLoss, _digits);
        tp = NormalizeDouble(Bid + takeProfit, _digits);
   }

   if (operation == OP_SELL) {
        price = Bid;
        sl = NormalizeDouble(Ask + stopLoss, _digits);
        tp = NormalizeDouble(Ask - takeProfit, _digits);
   }

   return OpenOrderInt(operation, lot, price, sl, takeProfit, NULL /* comment */, magicNumber);
}

bool PSMarket::OpenOrderInt(int operation, double lot, double price, double stopLoss = 0, double takeProfit = 0, 
   string commentOrder = NULL, int magicNumber = 0, datetime expiration = 0)
{
   int ticket = OrderSend(_symbol, operation, lot, price, _slippage, stopLoss, takeProfit, commentOrder, magicNumber, expiration, OrderTypeToColor(operation, true));
   
   if(ticket == -1)
   {
      LogError(StringConcatenate(__FUNCTION__, " Failed to Open New ", operation == OP_BUY ? "Buy" : "Sell", " order "));

      return false;
   }

   return true;
}

color PSMarket::OrderTypeToColor(int orderType, bool isOpen)
{
   if (orderType == OP_BUY || orderType == OP_BUYLIMIT || orderType == OP_BUYSTOP) 
   {
      return isOpen ? clrRed : clrMagenta;
   }
   
   if (orderType == OP_SELL || orderType == OP_SELLLIMIT || orderType == OP_SELLSTOP) 
   {
      return isOpen ? clrBlue : clrDeepSkyBlue;
   }

   return clrWhite;
}

string PSMarket::OrderTypeToString(int orderType)
{
   string result = NULL;
   switch (orderType)
   {
      case OP_BUY : result = "Buy"; break;
      case OP_SELL : result = "Sell"; break;
      case OP_BUYLIMIT : result = "Buy Limit"; break;
      case OP_SELLLIMIT : result = "Sell Limit"; break;
      case OP_BUYSTOP : result = "Buy Stop"; break;
      case OP_SELLSTOP : result = "Sell Stop"; break;
   
      default: result = "Unknown"; break;
   }
   
   return result;
}

void PSMarket::LogError(string message)
{
      int error = GetLastError();

      _log.Error(StringConcatenate(message, " Error code = ", error, ", ",ErrorDescription(error), "."));
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