/*
���  ������  ����������  �������  �������� ����� 
JJMASeries.mqh 
PriceSeries.mqh 
� ����� (����������): MetaTrader\experts\include\
Heiken Ashi#.mq4
� ����� (����������): MetaTrader\indicators\
*/
//+------------------------------------------------------------------+  
//|                                                        J2JMA.mq4 | 
//|                       JMA code: Copyright � 2005, Jurik Research | 
//|                                          http://www.jurikres.com | 
//|    MQL4 JJMASeries+J2JMA: Copyright � 2006,     Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+  
#property copyright "Copyright � 2006, Nikolay Kositsin"
#property link "farria@mail.redcom.ru" 
//---- ��������� ���������� � ������� ����
#property indicator_chart_window 
//---- ���������� ������������ �������
#property indicator_buffers 1 
//---- ���� ����������
#property indicator_color1 Magenta 
//---- ������� ��������� ���������� -----------------------------------------------------------------------------------------------------+
extern int Length1 = 5; // �������  ������� ����������� 
extern int Length2 = 5; // �������  ������� ����������� 
extern int Phase1  = 100; // �������� ������� �����������, ������������ � �������� -100 ... +100, ������ �� �������� ����������� ��������; 
extern int Phase2  = 100; // �������� ������� �����������, ������������ � �������� -100 ... +100, ������ �� �������� ����������� ��������; 
extern int Shift   = 0; // c���� ���������� ����� ��� ������� 
extern int Input_Price_Customs = 0;/* ����� ���, �� ������� ������������ ������ ���������� 
(0-CLOSE, 1-OPEN, 2-HIGH, 3-LOW, 4-MEDIAN, 5-TYPICAL, 6-WEIGHTED, 7-Heiken Ashi Close, 8-SIMPL, 9-TRENDFOLLOW, 10-0.5*TRENDFOLLOW,
11-Heiken Ashi Low, 12-Heiken Ashi High,  13-Heiken Ashi Open, 14-Heiken Ashi Close.) */
//---- ----------------------------------------------------------------------------------------------------------------------------------+
//---- ������������ ������
double J2JMA[];
//---- ���������� � ��������� ������  
double Temp_Series;
//+------------------------------------------------------------------+  
//----+ �������� ������� JJMASeries 
//----+ �������� ������� JJMASeriesResize 
//----+ �������� ������� JJMASeriesAlert  
//----+ �������� ������� JMA_ErrDescr  
#include <JJMASeries.mqh> 
//+------------------------------------------------------------------+  
//----+ �������� ������� PriceSeries
//----+ �������� ������� PriceSeriesAlert 
#include <PriceSeries.mqh>
//+------------------------------------------------------------------+     
//| J2JMA indicator initialization function                          | 
//+------------------------------------------------------------------+  
int init() 
{  
//---- ����������� ����� ���������� �������
SetIndexStyle (0,DRAW_LINE); 
//---- 1 ������������ ����� ����������� ��� �����
SetIndexBuffer(0,J2JMA);
//---- �������������� ����� ������������ ����� 
SetIndexShift (0, Shift);  
//---- ��������� �������� ����������, ������� �� ����� ������ �� �������
SetIndexEmptyValue(0,0); 
//---- ��� ��� ���� ������ � ����� ��� �������� 
IndicatorShortName ("J2JMA( Length1="+Length1+", Phase1="+Phase1+", Length2="+Length2+", Phase2="+Phase2+", Shift="+Shift+")"); 
SetIndexLabel (0, "J2JMA"); 
//---- ��������� ������� �������� ����������� ����������
IndicatorDigits(Digits);
//----+ ��������� �������� �������� ���������� ������� JJMASeries, nJMAnumber=2(��� ��������� � ������� JJMASeries)
if (JJMASeriesResize(2)!=2)return(-1);
//---- ��������� ������� �� ������������ �������� ������� ����������
JJMASeriesAlert (0,"Length1",Length1);
JJMASeriesAlert (0,"Length2",Length2);
JJMASeriesAlert (1,"Phase1", Phase1 );
JJMASeriesAlert (1,"Phase2", Phase2 );
PriceSeriesAlert(Input_Price_Customs);
//---- ���������� �������������
return(0); 
} 
//+------------------------------------------------------------------+  
//| J2JMA iteration function                                         | 
//+------------------------------------------------------------------+  
int start() 
{ 
//---- �������� ���������� ����� �� ������������� ��� ����������� �������
if (Bars-1<61)return(0);
//----+ �������� ����� ���������� � ��������� ��� ������������ �����
int reset,MaxBar1,MaxBar2,counted_bars=IndicatorCounted();
//---- �������� �� ��������� ������
if (counted_bars<0)return(-1);
//---- ��������� ������������ ��� ������ ���� ���������� 
//---- (��� ����� ��������� ��� counted_bars ������� JJMASeries ����� �������� �����������!!!)
if (counted_bars>0) counted_bars--;
//---- ����������� ������ ������ ������� ����, ������� � �������� ����� �������� �������� ����� �����
int limit=Bars-counted_bars-1; MaxBar1=Bars-1; MaxBar2=MaxBar1-30;

//----+ �������� ���� ���������� ���������� 
for(int bar=limit;bar>=0;bar--)
{
//----+ ��������� � ������� PriceSeries ��� ��������� ������� ���� Series
Temp_Series=PriceSeries(Input_Price_Customs, bar);
//+----------------------------------------------------------------------------+ 
//----+ ��� ��������� � ������� JJMASeries �� �������� 0, 1. ��������� nJMA.Phase � nJMA.Length �� �������� �� ������ ���� (nJMA.din=0)
//(�� ������  ��������� �������� nJMA.MaxBar  �������� �� 30  �. �. ��� ��������� JMA �����������)
//+----------------------------------------------------------------------------+   
Temp_Series=JJMASeries(0,0,MaxBar1,limit,Phase1,Length1,Temp_Series,bar,reset);
//----+ �������� �� ���������� ������ � ���������� ��������
if(reset!=0)return(-1);
//+----------------------------------------------------------------------------+ 
Temp_Series=JJMASeries(1,0,MaxBar2,limit,Phase2,Length2,Temp_Series,bar,reset);
//----+ �������� �� ���������� ������ � ���������� ��������
if(reset!=0)return(-1);
//+----------------------------------------------------------------------------+ 
J2JMA[bar]=Temp_Series;
}
//---- ���������� ���������� �������� ����������
return(0); 
} 
//+---------------------------------------------------------------+

