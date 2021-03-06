//Version  January 7, 2007 Final
//+------------------------------------------------------------------+
//|                                                 JJMASeries().mqh |
//|                       JMA code: Copyright © 1998, Jurik Research |
//|                                          http://www.jurikres.com | 
//|              MQL4 JJMASeries: Copyright © 2006, Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+ 
  /*
  +SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS <<< Функция JJMASeries() >>> SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+

  +-----------------------------------------+ <<< Назначение >>> +----------------------------------------------------+

  Функция  JJMASeries()  предназначена  для  использования  алгоритма  JMA при написании любых индикаторов теханализа и
  экспертов,  для  замены  расчёта  классического  усреднения  на  этот  алгоритм.  Функция  не работает, если параметр
  nJMA.limit принимает значение, равное нулю! Все индикаторы, сделанные мною для JJMASeries(), выполнены с учётом этого
  ограничения.  Файл следует положить в папку MetaTrader\experts\include\ Следует учесть, что если nJMA.bar больше, чем
  nJMA.MaxBar,  то функция JJMASeries() возвращает значение равное нулю! на этом баре! И, следовательно, такое значение
  не  может  присутствовать  в  знаменателе  какой-либо  дроби  в  расчёте  индикатора! Эта версия функции JJMASeries()
  поддерживает  экспертов при её использовании в пользовательских индикаторах, к которым обращается эксперт. Эта версия
  функции  JJMASeries()  поддерживает экспертов при её использовании в коде индикатора, который полностью помещён в код
  эксперта  с  сохранением  всех  операторов цикла и переменных! При написании индикаторов и экспертов с использованием
  функции  JJMASeries(),  не  рекомендуется  переменным  давать  имена  начинающиеся  с  nJMA....  или dJMA.... Функция
  JJMASeries()  может  быть  использована  во  внутреннем  коде  других  пользовательских  функций, но при этом следует
  учитывать тот факт, что в каждом обращении к такой пользовательской функции у каждого обращения к JJMASeries() должен
  быть  свой  уникальный  номер  nJMA.number.  Функция  JJMASeries()  может быть использована во внутреннем коде других
  пользовательских  функций,  но  при  этом следует учитывать тот факт, что в каждом обращении к такой пользовательской
  функции у каждого обращения к JJMASeries() должен быть свой уникальный номер (nJMA.number). 
  
  +-------------------------------------+ <<< Входные параметры >>> +-------------------------------------------------+

  nJMA.number - порядковый номер обращения к функции JJMASeries(). (0, 1, 2, 3 и.т.д....)
  nJMA.dinJ   - параметр, позволяющий изменять параметры nJMA.Length и nJMA.Phase на каждом баре. 0 -  запрет изменения 
                параметров, любое другое значение - разрешение.
  nJMA.MaxBar - Максимальное  значение,  которое  может  принимать  номер  рассчитываемого  бара(bar).     Обычно равно 
                Bars-1-period;    Где "period" - это количество баров,  на которых  исходная  величина  dJMA.series  не 
                рассчитывается;
  nJMA.limit  - Количество ещё не подсчитанных баров плюс один или номер последнего непосчитанного бара,    Должно быть 
                обязательно равно  Bars-IndicatorCounted()-1;
  nJMA.Length - глубина сглаживания
  nJMA.Phase  - параметр, изменяющийся в пределах -100 ... +100, влияет на качество переходного процесса;
  dJMA.series - Входной  параметр, по которому производится расчёт функции JJMASeries();
  nJMA.bar    - номер рассчитываемого бара, параметр должен  изменяться  оператором  цикла  от максимального значения к 
                нулевому. Причём его максимальное значение всегда должно равняться значению параметра nJMA.limit!!!

  +------------------------------------+ <<< Выходные параметры >>> +-------------------------------------------------+

  JJMASeries()- значение функции dJMA.JMA.   При  значениях  nJMA.bar  больше  чем  nJMA.MaxBar-30 функция JJMASeries() 
                всегда возвращает ноль!!!
  nJMA.reset  - параметр,  возвращающий по ссылке значение, отличенное от 0 , если  произошла ошибка в расчёте функции,
                0, если расчёт прошёл нормально. Этот параметр может быть только переменной, но не значением!!!!
                 
  +-----------------------------------+ <<< Инициализация функции >>> +-----------------------------------------------+
  
  Перед обращениями к функции JJMASeries(), когда количество уже подсчитанных баров равно 0, (а ещё лучше это сделать в
  блоке  инициализации  пользовательского  индикатора  или  эксперта)   следует  изменить  размеры  внутренних буферных
  переменных   функции,  для   этого   необходимо  обратиться  к  функции  JJMASeries() через  вспомогательную  функцию
  JJMASeriesResize() со   следующими   параметрами:   JJMASeriesResize(nJMA.number+1);   необходимо   сделать  параметр
  nJMA.number(MaxJMA.number) равным  количеству обращений  к  функции  JJMASeries(),  то  есть  на  единицу больше, чем
  максимальный nJMA.number. 
  
  +--------------------------------------+ <<< Индикация ошибок >>> +-------------------------------------------------+
  
  При отладке индикаторов и экспертов их коды могут содержать ошибки, для выяснения причин которых следует смотреть лог
  файл.  Все  ошибки  функция JJMASeries() пишет в лог файл в папке \MetaTrader\EXPERTS\LOGS\. Если, перед обращением к
  функции  JJMASeries()  в коде, который предшествовал функции, возникла MQL4 ошибка, то функция запишет в лог файл код
  ошибки  и содержание ошибки. Если при выполнении функции JJMASeries() в алгоритме JJMASeries() произошла MQL4 ошибка,
  то  функция  также  запишет  в  лог  файл код ошибки и содержание ошибки. При неправильном задании номера обращения к
  функции  JJMASeries()  nJMA.number  или  неверном определении размера буферных переменных nJJMAResize.Size в лог файл
  будет записаны сообщения о неверном определении этих параметров. Также в лог файл пишется информация при неправильном
  определении  параметра  nJMA.limit.  Если  при  выполнении  функции инициализации init() произошёл сбой при изменении
  размеров  буферных  переменных  функции  JJMASeries(),  то  функция  JJMASeriesResize запишет в лог файл информацию о
  неудачном  изменении  размеров  буферных  переменных. Если при обращении к функции JJMASeries()через внешний оператор
  цикла  была  нарушена  правильная последовательность изменения параметра nJMA.bar, то в лог файл будет записана и эта
  информация. Следует учесть, что некоторые ошибки программного кода будут порождать дальнейшие ошибки в его исполнении
  и  поэтому,  если  функция  JJMASeries()пишет  в  лог  файл сразу несколько ошибок, то устранять их следует в порядке
  времени  возникновения.  В правильно написанном индикаторе функция JJMASeries() может делать записи в лог файл только
  при  нарушениях  работы операционной системы. Исключение составляет запись изменения размеров буферных переменных при
  перезагрузке индикатора или эксперта, которая происходит при каждом вызове функции init(). 
  
  +---------------------------------+ <<< Пример обращения к функции >>> +--------------------------------------------+

//----+ определение функций JJMASeries()
#include <JJMASeries.mqh>
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- определение стиля исполнения графика
SetIndexStyle (0,DRAW_LINE); 
//---- 1 индикаторный буфер использован для счёта
SetIndexBuffer(0,Ind_Buffer);
//----+ Изменение размеров буферных переменных функции JJMASeries, nJMA.number=1(Одно обращение к функции JJMASeries)
if(JJMASeriesResize(1)==0)return(-1);
return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator function                                        |
//+------------------------------------------------------------------+
int start()
{
//----+ Введение целых переменных и получение уже подсчитанных баров
int reset,bar,MaxBar,limit,counted_bars=IndicatorCounted(); 
//---- проверка на возможные ошибки
if (counted_bars<0)return(-1);
//---- последний подсчитанный бар должен быть пересчитан (без этого пересчёта функция JJMASeries() свой расчёт производить не будет!!!)
if (counted_bars>0) counted_bars--;
//---- определение номера самого старого бара, начиная с которого будет произедён пересчёт новых баров
int limit=Bars-counted_bars-1;
MaxBar=Bars-1;
//----+ 
for(bar=limit;bar>=0;bar--)
 (
  double Series=Close[bar];
  //----+ Обращение к функции JJMASeries() за номером 0 для расчёта буфера Ind_Buffer[], 
  //параметры nJMA.Phase и nJMA.Length не меняются на каждом баре (nJMA.din=0)
  double Resalt=JJMASeries(0,0,MaxBar,limit,Phase,Length,Series,bar,reset);
  if (reset!=0)return(-1);
  Ind_Buffer[bar]=Resalt;
 }
return(0);
}
//----+ 

  */
//SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+
//+++++++++++++++++++++++++++++++++++++++++++++++++++++ <<< JJMASeries()>>> ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++|
//SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+

//----++ <<< Введение переменных >>> +SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+

double dJMA_f18[1],dJMA_f38[1],dJMA_fA8[1],dJMA_fC0[1],dJMA_fC8[1],dJMA_s8[1],dJMA_s18[1],dJMA_v1[1],dJMA_v2[1];
double dJMA_v3[1],dJMA_f90[1],dJMA_f78[1],dJMA_f88[1],dJMA_f98[1],dJMA_JMA[1],dJMA_list[1][128],dJMA_ring1[1][128];
double dJMA_ring2[1][11],dJMA_buffer[1][62],dJMA_mem1[1][8],dJMA_mem3[1][128],dJMA_RING1[1][128],dJMA_RING2[1][11];
double dJMA_LIST[1][128],dJMA_Kg[1],dJMA_Pf[1];
//--+
int    nJMA_s28[1],nJMA_s30[1],nJMA_s38[1],nJMA_s40[1],nJMA_s48[1],nJMA_f0[1],nJMA_s50[1],nJMA_s70[1],nJMA_LP2[1];   
int    nJMA_LP1[1],nJMA_mem2[1][7],nJMA_mem7[1][11];
int    nJMA_TIME[1];
//--+ +-------------------------------------------------------------------------------------------------------------+
double dJMA_fA0,dJMA_vv,dJMA_v4,dJMA_f70,dJMA_s20,dJMA_s10,dJMA_fB0,dJMA_fD0,dJMA_f8,dJMA_f60,dJMA_f20,dJMA_f28;
double dJMA_f30,dJMA_f40,dJMA_f48,dJMA_f58,dJMA_f68;
//--+
int    nJMA_v5,nJMA_v6,nJMA_fE0,nJMA_fD8,nJMA_fE8,nJMA_val,nJMA_s58,nJMA_s60,nJMA_s68,nJMA_aa,nJMA_size;
int    nJMA_ii,nJMA_jj,nJMA_m,nJMA_n,nJMA_Tnew,nJMA_Told,nJMA_Error,nJMA_Resize;

//----++ <<< Объявление функции JJMASeries() >>> +SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+

double JJMASeries
(
int nJMA_number, int nJMA_din,       int nJMA_MaxBar, int nJMA_limit,
int nJMA_Phase,  int nJMA_Length, double dJMA_series, int nJMA_bar,   int& nJMA_reset
)
//----++ +SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+
{
nJMA_n=nJMA_number;

nJMA_reset=1;
//=====+ <<< Проверки на ошибки >>> ====================================================================================================+
if (nJMA_bar==nJMA_limit)
 {
  //----++ проверка на инициализацию функции JJMASeries()
  if(nJMA_Resize<1)
   {
    Print("JJMASeries number ="+nJMA_n+
         ". Не было сделано изменение размеров буферных переменных функцией JJMASeriesResize()");
    if(nJMA_Resize==0)
        Print("JJMASeries number ="+nJMA_n+
                ". Следует дописать обращение к функции JJMASeriesResize() в блок инициализации");
    return(0.0);
   }
  //----++ проверка на ошибку в исполнении программного кода, предшествовавшего функции JJMASeries()
  nJMA_Error=GetLastError();
  if(nJMA_Error>4000)
   {
    Print("JJMASeries number ="+nJMA_n+
         ". В коде, предшествующем обращению к функции JJMASeries() number = "+nJMA_n+" ошибка!!!");
    Print("JJMASeries number ="+nJMA_n+ ". ",JMA_ErrDescr(nJMA_Error));  
   } 
                                                   
  //----++ проверка на ошибку в задании переменных nJMA_number и nJMAResize.Number
  nJMA_size=ArraySize(dJMA_JMA);
  if (nJMA_size< nJMA_n) 
   {
    Print("JJMASeries number ="+nJMA_n+
          ". Ошибка!!! Неправильно задано значение переменной nJMA_number="
                                                        +nJMA_n+" функции JJMASeries()");
    Print("JJMASeries number ="+nJMA_n+
          ". Или неправильно задано значение  переменной nJJMAResize_Size="
                                               +nJMA_size+" функции JJMASeriesResize()");
    return(0.0);
   }
 }
//----++ проверка на ошибку в последовательности изменения переменной nJMA_bar
if((nJMA_limit>=nJMA_MaxBar)&&(nJMA_bar==0))
    if((nJMA_MaxBar>30)&&(nJMA_TIME[nJMA_n]==0))
                  Print("JJMASeries number ="+nJMA_n+
                        ". Ошибка!!! Нарушена правильная последовательность изменения параметра nJMA_bar внешним оператором цикла!!!");  
//----++ +==============================================================================================================================+ 
if (nJMA_bar> nJMA_MaxBar){nJMA_reset=0;return(0.0);}
if((nJMA_bar==nJMA_MaxBar)||(nJMA_din!=0)) 
  {
   //----++ <<< Расчёт коэффициентов  >>> +SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+
   double nJMA_Dr,nJMA_Ds,nJMA_Dl;
   if(nJMA_Length < 1.0000000002) nJMA_Dr = 0.0000000001;
   else nJMA_Dr= (nJMA_Length - 1.0) / 2.0;
   if((nJMA_Phase >= -100)&&(nJMA_Phase <= 100))dJMA_Pf[nJMA_n] = nJMA_Phase / 100.0 + 1.5;
   if (nJMA_Phase > 100) dJMA_Pf[nJMA_n] = 2.5;
   if (nJMA_Phase < -100) dJMA_Pf[nJMA_n] = 0.5;
   nJMA_Dr = nJMA_Dr * 0.9; dJMA_Kg[nJMA_n] = nJMA_Dr/(nJMA_Dr + 2.0);
   nJMA_Ds=MathSqrt(nJMA_Dr);nJMA_Dl=MathLog(nJMA_Ds); dJMA_v1[nJMA_n]= nJMA_Dl;dJMA_v2[nJMA_n] = dJMA_v1[nJMA_n];
   if((dJMA_v1[nJMA_n] / MathLog(2.0)) + 2.0 < 0.0) dJMA_v3[nJMA_n]= 0.0;
   else dJMA_v3[nJMA_n]=(dJMA_v2[nJMA_n]/MathLog(2.0))+ 2.0;
   dJMA_f98[nJMA_n]= dJMA_v3[nJMA_n];
   if( dJMA_f98[nJMA_n] >= 2.5 ) dJMA_f88[nJMA_n] = dJMA_f98[nJMA_n] - 2.0;
   else dJMA_f88[nJMA_n]= 0.5;
   dJMA_f78[nJMA_n]= nJMA_Ds * dJMA_f98[nJMA_n]; dJMA_f90[nJMA_n]= dJMA_f78[nJMA_n] / (dJMA_f78[nJMA_n] + 1.0);
   //----++SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+
  }
//--+
if((nJMA_bar==nJMA_limit)&&(nJMA_limit<nJMA_MaxBar))
  {
   //----+ <<< Восстановление значений переменных >>> +SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+
   nJMA_Tnew=Time[nJMA_limit+1];
   nJMA_Told=nJMA_TIME[nJMA_n];
   //--+
   if(nJMA_Tnew==nJMA_Told)
     {
      for(nJMA_aa=127;nJMA_aa>=0;nJMA_aa--)dJMA_list [nJMA_n][nJMA_aa]=dJMA_LIST [nJMA_n][nJMA_aa];
      for(nJMA_aa=127;nJMA_aa>=0;nJMA_aa--)dJMA_ring1[nJMA_n][nJMA_aa]=dJMA_RING1[nJMA_n][nJMA_aa];
      for(nJMA_aa=10; nJMA_aa>=0;nJMA_aa--)dJMA_ring2[nJMA_n][nJMA_aa]=dJMA_RING2[nJMA_n][nJMA_aa];
      //--+
      dJMA_fC0[nJMA_n]=dJMA_mem1[nJMA_n][00];dJMA_fC8[nJMA_n]=dJMA_mem1[nJMA_n][01];dJMA_fA8[nJMA_n]=dJMA_mem1[nJMA_n][02];
      dJMA_s8 [nJMA_n]=dJMA_mem1[nJMA_n][03];dJMA_f18[nJMA_n]=dJMA_mem1[nJMA_n][04];dJMA_f38[nJMA_n]=dJMA_mem1[nJMA_n][05];
      dJMA_s18[nJMA_n]=dJMA_mem1[nJMA_n][06];dJMA_JMA[nJMA_n]=dJMA_mem1[nJMA_n][07];nJMA_s38[nJMA_n]=nJMA_mem2[nJMA_n][00];
      nJMA_s48[nJMA_n]=nJMA_mem2[nJMA_n][01];nJMA_s50[nJMA_n]=nJMA_mem2[nJMA_n][02];nJMA_LP1[nJMA_n]=nJMA_mem2[nJMA_n][03];
      nJMA_LP2[nJMA_n]=nJMA_mem2[nJMA_n][04];nJMA_s40[nJMA_n]=nJMA_mem2[nJMA_n][05];nJMA_s70[nJMA_n]=nJMA_mem2[nJMA_n][06];
     } 
   //--+ проверка на ошибки
   if(nJMA_Tnew!=nJMA_Told)
    {
     nJMA_reset=-1;
     //--+ индикация ошибки в расчёте входного параметра nJMA_limit функции JJMASeries()
     if (nJMA_Tnew>nJMA_Told)
       {
        Print("JJMASeries number ="+nJMA_n+
                 ". Ошибка!!! Параметр nJMA_limit функции JJMASeries() меньше, чем необходимо");
       }
     else 
       { 
        int nJMA_LimitERROR=nJMA_limit+1-iBarShift(NULL,0,nJMA_Told,TRUE);
        Print("JMASerries number ="+nJMA_n+
                ". Ошибка!!! Параметр nJMA_limit функции JJMASeries() больше, чем необходимо на "
                                                                                        +nJMA_LimitERROR+"");
       }
     //--+ Возврат через nJMA_reset=-1; ошибки в расчёте функции JJMASeries
     return(0);
    }
  //----+SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+
  } 
if (nJMA_bar==1)    
if (( nJMA_limit!=1)||(Time[nJMA_limit+2]==nJMA_TIME[nJMA_n]))
  {
   //--+ <<< Сохранение значений переменных >>> +SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+
   for(nJMA_aa=127;nJMA_aa>=0;nJMA_aa--)dJMA_LIST [nJMA_n][nJMA_aa]=dJMA_list [nJMA_n][nJMA_aa];
   for(nJMA_aa=127;nJMA_aa>=0;nJMA_aa--)dJMA_RING1[nJMA_n][nJMA_aa]=dJMA_ring1[nJMA_n][nJMA_aa];
   for(nJMA_aa=10; nJMA_aa>=0;nJMA_aa--)dJMA_RING2[nJMA_n][nJMA_aa]=dJMA_ring2[nJMA_n][nJMA_aa];
   //--+
   dJMA_mem1[nJMA_n][00]=dJMA_fC0[nJMA_n];dJMA_mem1[nJMA_n][01]=dJMA_fC8[nJMA_n];dJMA_mem1[nJMA_n][02]=dJMA_fA8[nJMA_n];
   dJMA_mem1[nJMA_n][03]=dJMA_s8 [nJMA_n];dJMA_mem1[nJMA_n][04]=dJMA_f18[nJMA_n];dJMA_mem1[nJMA_n][05]=dJMA_f38[nJMA_n];
   dJMA_mem1[nJMA_n][06]=dJMA_s18[nJMA_n];dJMA_mem1[nJMA_n][07]=dJMA_JMA[nJMA_n];nJMA_mem2[nJMA_n][00]=nJMA_s38[nJMA_n];
   nJMA_mem2[nJMA_n][01]=nJMA_s48[nJMA_n];nJMA_mem2[nJMA_n][02]=nJMA_s50[nJMA_n];nJMA_mem2[nJMA_n][03]=nJMA_LP1[nJMA_n];
   nJMA_mem2[nJMA_n][04]=nJMA_LP2[nJMA_n];nJMA_mem2[nJMA_n][05]=nJMA_s40[nJMA_n];nJMA_mem2[nJMA_n][06]=nJMA_s70[nJMA_n];
   nJMA_TIME[nJMA_n]=Time[2];
   //--+SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+
  } 
//----+
if (nJMA_LP1[nJMA_n]<61){nJMA_LP1[nJMA_n]++; dJMA_buffer[nJMA_n][nJMA_LP1[nJMA_n]]=dJMA_series;}
if (nJMA_LP1[nJMA_n]>30)
{
//++++++++++++++++++
if (nJMA_f0[nJMA_n] != 0)
{
nJMA_f0[nJMA_n] = 0; 
nJMA_v5 = 1;
nJMA_fD8 = nJMA_v5*30;
if (nJMA_fD8 == 0) dJMA_f38[nJMA_n] = dJMA_series; else dJMA_f38[nJMA_n] = dJMA_buffer[nJMA_n][1];
dJMA_f18[nJMA_n] = dJMA_f38[nJMA_n];
if (nJMA_fD8 > 29) nJMA_fD8 = 29;
}
else nJMA_fD8 = 0;
for(nJMA_ii=nJMA_fD8; nJMA_ii>=0; nJMA_ii--)
{
nJMA_val=31-nJMA_ii;
if (nJMA_ii == 0) dJMA_f8 = dJMA_series; else dJMA_f8 = dJMA_buffer[nJMA_n][nJMA_val];
dJMA_f28 = dJMA_f8 - dJMA_f18[nJMA_n]; dJMA_f48 = dJMA_f8 - dJMA_f38[nJMA_n];
if (MathAbs(dJMA_f28) > MathAbs(dJMA_f48)) dJMA_v2[nJMA_n] = MathAbs(dJMA_f28); else dJMA_v2[nJMA_n] = MathAbs(dJMA_f48);
dJMA_fA0 = dJMA_v2[nJMA_n]; dJMA_vv = dJMA_fA0 + 0.0000000001; //{1.0e-10;}
if (nJMA_s48[nJMA_n] <= 1) nJMA_s48[nJMA_n] = 127; else nJMA_s48[nJMA_n] = nJMA_s48[nJMA_n] - 1;
if (nJMA_s50[nJMA_n] <= 1) nJMA_s50[nJMA_n] = 10;  else nJMA_s50[nJMA_n] = nJMA_s50[nJMA_n] - 1;
if (nJMA_s70[nJMA_n] < 128) nJMA_s70[nJMA_n] = nJMA_s70[nJMA_n] + 1;
dJMA_s8[nJMA_n] = dJMA_s8[nJMA_n] + dJMA_vv - dJMA_ring2[nJMA_n][nJMA_s50[nJMA_n]];
dJMA_ring2[nJMA_n][nJMA_s50[nJMA_n]] = dJMA_vv;
if (nJMA_s70[nJMA_n] > 10) dJMA_s20 = dJMA_s8[nJMA_n] / 10.0; else dJMA_s20 = dJMA_s8[nJMA_n] / nJMA_s70[nJMA_n];
if (nJMA_s70[nJMA_n] > 127)
{
dJMA_s10 = dJMA_ring1[nJMA_n][nJMA_s48[nJMA_n]];
dJMA_ring1[nJMA_n][nJMA_s48[nJMA_n]] = dJMA_s20; nJMA_s68 = 64; nJMA_s58 = nJMA_s68;
while (nJMA_s68 > 1)
{
if (dJMA_list[nJMA_n][nJMA_s58] < dJMA_s10){nJMA_s68 = nJMA_s68 *0.5; nJMA_s58 = nJMA_s58 + nJMA_s68;}
else 
if (dJMA_list[nJMA_n][nJMA_s58]<= dJMA_s10) nJMA_s68 = 1; else{nJMA_s68 = nJMA_s68 *0.5; nJMA_s58 = nJMA_s58 - nJMA_s68;}
}
}
else
{
dJMA_ring1[nJMA_n][nJMA_s48[nJMA_n]] = dJMA_s20;
if  (nJMA_s28[nJMA_n] + nJMA_s30[nJMA_n] > 127){nJMA_s30[nJMA_n] = nJMA_s30[nJMA_n] - 1; nJMA_s58 = nJMA_s30[nJMA_n];}
else{nJMA_s28[nJMA_n] = nJMA_s28[nJMA_n] + 1; nJMA_s58 = nJMA_s28[nJMA_n];}
if  (nJMA_s28[nJMA_n] > 96) nJMA_s38[nJMA_n] = 96; else nJMA_s38[nJMA_n] = nJMA_s28[nJMA_n];
if  (nJMA_s30[nJMA_n] < 32) nJMA_s40[nJMA_n] = 32; else nJMA_s40[nJMA_n] = nJMA_s30[nJMA_n];
}
nJMA_s68 = 64; nJMA_s60 = nJMA_s68;
while (nJMA_s68 > 1)
{
if (dJMA_list[nJMA_n][nJMA_s60] >= dJMA_s20)
{
if (dJMA_list[nJMA_n][nJMA_s60 - 1] <= dJMA_s20) nJMA_s68 = 1; else {nJMA_s68 = nJMA_s68 *0.5; nJMA_s60 = nJMA_s60 - nJMA_s68; }
}
else{nJMA_s68 = nJMA_s68 *0.5; nJMA_s60 = nJMA_s60 + nJMA_s68;}
if ((nJMA_s60 == 127) && (dJMA_s20 > dJMA_list[nJMA_n][127])) nJMA_s60 = 128;
}
if (nJMA_s70[nJMA_n] > 127)
{
if (nJMA_s58 >= nJMA_s60)
{
if ((nJMA_s38[nJMA_n] + 1 > nJMA_s60) && (nJMA_s40[nJMA_n] - 1 < nJMA_s60)) dJMA_s18[nJMA_n] = dJMA_s18[nJMA_n] + dJMA_s20;
else 
if ((nJMA_s40[nJMA_n] + 0 > nJMA_s60) && (nJMA_s40[nJMA_n] - 1 < nJMA_s58)) dJMA_s18[nJMA_n] 
= dJMA_s18[nJMA_n] + dJMA_list[nJMA_n][nJMA_s40[nJMA_n] - 1];
}
else
if (nJMA_s40[nJMA_n] >= nJMA_s60) {if ((nJMA_s38[nJMA_n] + 1 < nJMA_s60) && (nJMA_s38[nJMA_n] + 1 > nJMA_s58)) dJMA_s18[nJMA_n] 
= dJMA_s18[nJMA_n] + dJMA_list[nJMA_n][nJMA_s38[nJMA_n] + 1]; }
else if  (nJMA_s38[nJMA_n] + 2 > nJMA_s60) dJMA_s18[nJMA_n] = dJMA_s18[nJMA_n] + dJMA_s20; 
else if ((nJMA_s38[nJMA_n] + 1 < nJMA_s60) && (nJMA_s38[nJMA_n] + 1 > nJMA_s58)) dJMA_s18[nJMA_n] 
= dJMA_s18[nJMA_n] + dJMA_list[nJMA_n][nJMA_s38[nJMA_n] + 1];
if (nJMA_s58 > nJMA_s60)
{
if ((nJMA_s40[nJMA_n] - 1 < nJMA_s58) && (nJMA_s38[nJMA_n] + 1 > nJMA_s58)) dJMA_s18[nJMA_n] = dJMA_s18[nJMA_n] - dJMA_list[nJMA_n][nJMA_s58];
else 
if ((nJMA_s38[nJMA_n]     < nJMA_s58) && (nJMA_s38[nJMA_n] + 1 > nJMA_s60)) dJMA_s18[nJMA_n] = dJMA_s18[nJMA_n] - dJMA_list[nJMA_n][nJMA_s38[nJMA_n]];
}
else
{
if ((nJMA_s38[nJMA_n] + 1 > nJMA_s58) && (nJMA_s40[nJMA_n] - 1 < nJMA_s58)) dJMA_s18[nJMA_n] = dJMA_s18[nJMA_n] - dJMA_list[nJMA_n][nJMA_s58];
else
if ((nJMA_s40[nJMA_n] + 0 > nJMA_s58) && (nJMA_s40[nJMA_n] - 0 < nJMA_s60)) dJMA_s18[nJMA_n] = dJMA_s18[nJMA_n] - dJMA_list[nJMA_n][nJMA_s40[nJMA_n]];
}
}
if (nJMA_s58 <= nJMA_s60)
{
if (nJMA_s58 >= nJMA_s60)
{
dJMA_list[nJMA_n][nJMA_s60] = dJMA_s20;
}
else
{
for( nJMA_jj = nJMA_s58 + 1; nJMA_jj<=nJMA_s60 - 1 ;nJMA_jj++)dJMA_list[nJMA_n][nJMA_jj - 1] = dJMA_list[nJMA_n][nJMA_jj];
dJMA_list[nJMA_n][nJMA_s60 - 1] = dJMA_s20;
}
}
else
{
for( nJMA_jj = nJMA_s58 - 1; nJMA_jj>=nJMA_s60 ;nJMA_jj--) dJMA_list[nJMA_n][nJMA_jj + 1] = dJMA_list[nJMA_n][nJMA_jj];
dJMA_list[nJMA_n][nJMA_s60] = dJMA_s20;
}
if (nJMA_s70[nJMA_n] <= 127)
{
dJMA_s18[nJMA_n] = 0;
for( nJMA_jj = nJMA_s40[nJMA_n] ; nJMA_jj<=nJMA_s38[nJMA_n] ;nJMA_jj++) dJMA_s18[nJMA_n] = dJMA_s18[nJMA_n] + dJMA_list[nJMA_n][nJMA_jj];
}
dJMA_f60 = dJMA_s18[nJMA_n] / (nJMA_s38[nJMA_n] - nJMA_s40[nJMA_n] + 1.0);
if (nJMA_LP2[nJMA_n] + 1 > 31) nJMA_LP2[nJMA_n] = 31; else nJMA_LP2[nJMA_n] = nJMA_LP2[nJMA_n] + 1;
if (nJMA_LP2[nJMA_n] <= 30)
{
if (dJMA_f28 > 0.0) dJMA_f18[nJMA_n] = dJMA_f8; else dJMA_f18[nJMA_n] = dJMA_f8 - dJMA_f28 * dJMA_f90[nJMA_n];
if (dJMA_f48 < 0.0) dJMA_f38[nJMA_n] = dJMA_f8; else dJMA_f38[nJMA_n] = dJMA_f8 - dJMA_f48 * dJMA_f90[nJMA_n];
dJMA_JMA[nJMA_n] = dJMA_series;
if (nJMA_LP2[nJMA_n]!=30) continue;
if (nJMA_LP2[nJMA_n]==30)
{
dJMA_fC0[nJMA_n] = dJMA_series;
if ( MathCeil(dJMA_f78[nJMA_n]) >= 1) dJMA_v4 = MathCeil(dJMA_f78[nJMA_n]); else dJMA_v4 = 1.0;

if(dJMA_v4>0)nJMA_fE8 = MathFloor(dJMA_v4);else{if(dJMA_v4<0)nJMA_fE8 = MathCeil (dJMA_v4);else nJMA_fE8 = 0.0;}

if (MathFloor(dJMA_f78[nJMA_n]) >= 1) dJMA_v2[nJMA_n] = MathFloor(dJMA_f78[nJMA_n]); else dJMA_v2[nJMA_n] = 1.0;

if(dJMA_v2[nJMA_n]>0)nJMA_fE0 = MathFloor(dJMA_v2[nJMA_n]);else{if(dJMA_v2[nJMA_n]<0)nJMA_fE0 = MathCeil (dJMA_v2[nJMA_n]);else nJMA_fE0 = 0.0;}

if (nJMA_fE8== nJMA_fE0) dJMA_f68 = 1.0; else {dJMA_v4 = nJMA_fE8 - nJMA_fE0; dJMA_f68 = (dJMA_f78[nJMA_n] - nJMA_fE0) / dJMA_v4;}
if (nJMA_fE0 <= 29) nJMA_v5 = nJMA_fE0; else nJMA_v5 = 29;
if (nJMA_fE8 <= 29) nJMA_v6 = nJMA_fE8; else nJMA_v6 = 29;
dJMA_fA8[nJMA_n] = (dJMA_series - dJMA_buffer[nJMA_n][nJMA_LP1[nJMA_n] - nJMA_v5]) * (1.0 - dJMA_f68) / nJMA_fE0 + (dJMA_series 
- dJMA_buffer[nJMA_n][nJMA_LP1[nJMA_n] - nJMA_v6]) * dJMA_f68 / nJMA_fE8;
}
}
else
{
if (dJMA_f98[nJMA_n] >= MathPow(dJMA_fA0/dJMA_f60, dJMA_f88[nJMA_n])) dJMA_v1[nJMA_n] = MathPow(dJMA_fA0/dJMA_f60, dJMA_f88[nJMA_n]);
else dJMA_v1[nJMA_n] = dJMA_f98[nJMA_n];
if (dJMA_v1[nJMA_n] < 1.0) dJMA_v2[nJMA_n] = 1.0;
else
{if(dJMA_f98[nJMA_n] >= MathPow(dJMA_fA0/dJMA_f60, dJMA_f88[nJMA_n])) dJMA_v3[nJMA_n] = MathPow(dJMA_fA0/dJMA_f60, dJMA_f88[nJMA_n]);
else dJMA_v3[nJMA_n] = dJMA_f98[nJMA_n]; dJMA_v2[nJMA_n] = dJMA_v3[nJMA_n];}
dJMA_f58 = dJMA_v2[nJMA_n]; dJMA_f70 = MathPow(dJMA_f90[nJMA_n], MathSqrt(dJMA_f58));
if (dJMA_f28 > 0.0) dJMA_f18[nJMA_n] = dJMA_f8; else dJMA_f18[nJMA_n] = dJMA_f8 - dJMA_f28 * dJMA_f70;
if (dJMA_f48 < 0.0) dJMA_f38[nJMA_n] = dJMA_f8; else dJMA_f38[nJMA_n] = dJMA_f8 - dJMA_f48 * dJMA_f70;
}
}
if (nJMA_LP2[nJMA_n] >30)
{
dJMA_f30 = MathPow(dJMA_Kg[nJMA_n], dJMA_f58);
dJMA_fC0[nJMA_n] =(1.0 - dJMA_f30) * dJMA_series + dJMA_f30 * dJMA_fC0[nJMA_n];
dJMA_fC8[nJMA_n] =(dJMA_series - dJMA_fC0[nJMA_n]) * (1.0 - dJMA_Kg[nJMA_n]) + dJMA_Kg[nJMA_n] * dJMA_fC8[nJMA_n];
dJMA_fD0 = dJMA_Pf[nJMA_n] * dJMA_fC8[nJMA_n] + dJMA_fC0[nJMA_n];
dJMA_f20 = dJMA_f30 *(-2.0);
dJMA_f40 = dJMA_f30 * dJMA_f30;
dJMA_fB0 = dJMA_f20 + dJMA_f40 + 1.0;
dJMA_fA8[nJMA_n] =(dJMA_fD0 - dJMA_JMA[nJMA_n]) * dJMA_fB0 + dJMA_f40 * dJMA_fA8[nJMA_n];
dJMA_JMA[nJMA_n] = dJMA_JMA[nJMA_n] + dJMA_fA8[nJMA_n];
}
}
//++++++++++++++++++
if (nJMA_LP1[nJMA_n] <=30)dJMA_JMA[nJMA_n]=0.0;
//----+ 

//----++ проверка на ошибку в исполнении программного кода функции JJMASeries()
nJMA_Error=GetLastError();
if(nJMA_Error>4000)
  {
    Print("JJMASeries number ="+nJMA_n+". При исполнении функции JJMASeries() произошла ошибка!!!");
    Print("JJMASeries number ="+nJMA_n+ ". ",JMA_ErrDescr(nJMA_Error));   
    return(0.0);
  }

nJMA_reset=0;
return(dJMA_JMA[nJMA_n]);
//----+  Завершение вычислений функции JJMASeries() --------------------------+
}

//SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+
// JJMASeriesResize - Это дополнительная функция для изменения размеров буферных переменных       | 
// функции JJMASeries. Пример обращения: JJMASeriesResize(5); где 5 - это количество обращений к  | 
// JJMASeries()в тексте индикатора. Это обращение к функции  JJMASeriesResize следует поместить   |
// в блок инициализации пользовательского индикатора или эксперта                                 |
//SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+
int JJMASeriesResize(int nJJMAResize_Size)
 {
//----+
  if(nJJMAResize_Size<1)
   {
    Print("JJMASeriesResize: Ошибка!!! Параметр nJJMAResize_Size не может быть меньше единицы!!!"); 
    nJMA_Resize=-1; 
    return(0);
   }  
  int nJJMAResize_reset,nJJMAResize_cycle;
  //--+
  while(nJJMAResize_cycle==0)
   {
    //----++ <<< изменение размеров буферных переменных >>> +SSSSSSSSSSSSSSSSSSSSSSS+
    if(ArrayResize(dJMA_list,  nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(dJMA_ring1, nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(dJMA_ring2, nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(dJMA_buffer,nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(dJMA_mem1,  nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(nJMA_mem2,  nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(nJMA_mem7,  nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(dJMA_mem3,  nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(dJMA_LIST,  nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(dJMA_RING1, nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(dJMA_RING2, nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(dJMA_Kg,    nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(dJMA_Pf,    nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(dJMA_f18,   nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(dJMA_f38,   nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(dJMA_fA8,   nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(dJMA_fC0,   nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(dJMA_fC8,   nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(dJMA_s8,    nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(dJMA_s18,   nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(dJMA_JMA,   nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(nJMA_s50,   nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(nJMA_s70,   nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(nJMA_LP2,   nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(nJMA_LP1,   nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(nJMA_s38,   nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(nJMA_s40,   nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(nJMA_s48,   nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(dJMA_v1,    nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(dJMA_v2,    nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(dJMA_v3,    nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(dJMA_f90,   nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(dJMA_f78,   nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(dJMA_f88,   nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(dJMA_f98,   nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(nJMA_s28,   nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(nJMA_s30,   nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(nJMA_f0,    nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    if(ArrayResize(nJMA_TIME,  nJJMAResize_Size)==0){nJJMAResize_reset=-1;break;}
    //+SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+
    nJJMAResize_cycle=1;
   }
  //--+
  if(nJJMAResize_reset==-1)
   {
    Print("JJMASeriesResize: Ошибка!!! Не удалось изменить размеры буферных переменных функции JJMASeries().");   
    int nJJMAResize_Error=GetLastError();
    if(nJJMAResize_Error>4000)Print("JJMASeriesResize(): ",JMA_ErrDescr(nJJMAResize_Error));                                                                                                                                                                                                            
    nJMA_Resize=-2;
    return(0);
   }
  else  
   {
    Print("JJMASeriesResize: JJMASeries()size = "+nJJMAResize_Size+"");

    //----+-------------------------------------------------------------------+
    ArrayInitialize(nJMA_f0,  1);
    ArrayInitialize(nJMA_s28,63);
    ArrayInitialize(nJMA_s30,64);
    for(int rrr=0;rrr<nJJMAResize_Size;rrr++)
     {
       for(int kkk=0;kkk<=nJMA_s28[rrr];kkk++)dJMA_list[rrr][kkk]=-1000000.0;
       for(kkk=nJMA_s30[rrr]; kkk<=127; kkk++)dJMA_list[rrr][kkk]= 1000000.0;
     }
    //----+-------------------------------------------------------------------+
    nJMA_Resize=nJJMAResize_Size;
    return(nJJMAResize_Size);
   }  
//----+
 }
//--+ --------------------------------------------------------------------------------------------+
/*
//SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+
JJMASeriesAlert  -  Это  дополнительная  функция  для  индикации ошибки в задании внешних переменных  | 
nJMA_Length и nJMA_Phase функции JJMASeries.                                                          |
  -------------------------- входные параметры  --------------------------                            |
JJMASeriesAlert_Number                                                                                |
JJMASeriesAlert_ExternVar значение внешней переменной для параметра nJMA_Length                       |
JJMASeriesAlert_name имя внешней переменной для параметра nJMA_Phase, если JJMASeriesAlert_Number=0   |
или nJMA_Phase, если JJMASeriesAlert_Number=1.                                                        |
  -------------------------- Пример использования  -----------------------                            |
  int init()                                                                                          |
//----                                                                                                |
Здесь какая-то инициализация переменных и буферов                                                     |
                                                                                                      |
//---- установка алертов на недопустимые значения внешних переменных                                  |
JJMASeriesAlert(0,"Length1",Length1);                                                                 |
JJMASeriesAlert(0,"Length2",Length2);                                                                 |
JJMASeriesAlert(1,"Phase1",Phase1);                                                                   |                                                            
JJMASeriesAlert(1,"Phase2",Phase2);                                                                   |                                                          
//---- завершение инициализации                                                                       |
return(0);                                                                                            |
}                                                                                                     |
//SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS+
*/
void JJMASeriesAlert
 (
  int JJMASeriesAlert_Number, string JJMASeriesAlert_name, int JJMASeriesAlert_ExternVar
 )
 {
  //---- установка алертов на недопустимые значения входных параметров ==========================+ 
  if(JJMASeriesAlert_Number==0)if(JJMASeriesAlert_ExternVar<1)
          {Alert("Параметр "+JJMASeriesAlert_name+" должен быть не менее 1" 
          + " Вы ввели недопустимое " +JJMASeriesAlert_ExternVar+ " будет использовано  1"  );}
  if(JJMASeriesAlert_Number==1)
   {
    if((JJMASeriesAlert_ExternVar<-100)||(JJMASeriesAlert_ExternVar> 100))
          {Alert("Параметр "+JJMASeriesAlert_name+" должен быть от -100 до +100" 
          + " Вы ввели недопустимое "+JJMASeriesAlert_ExternVar+  " будет использовано -100");}
   }
 }
//--+ --------------------------------------------------------------------------------------------+

/*
перевод сделан Николаем Косициным 01.12.2006  
//+------------------------------------------------------------------+
                                          JMA_ErrDescr(MQL4_RUS).mqh |
                         Copyright © 2004, MetaQuotes Software Corp. |
                                          http://www.metaquotes.net/ |
 функция JMA_ErrDescr() по коду MQL4 ошибки возвращает стринговую    |
 строку с кодом и содержанием ошибки.                                |
  -------------------- Пример использования  ----------------------- | 
 int Error=GetLastError();                                           |
 if(Error>4000)Print(JMA_ErrDescr(Error));                           |
//+------------------------------------------------------------------+
*/
string JMA_ErrDescr(int error_code)
 {
  string error_string;
//----
  switch(error_code)
    {
     //---- MQL4 ошибки 
     case 4000: error_string="Код ошибки = "+error_code+". нет ошибки";                                                  break;
     case 4001: error_string="Код ошибки = "+error_code+". Неправильный указатель функции";                              break;
     case 4002: error_string="Код ошибки = "+error_code+". индекс массива не соответствует его размеру";                 break;
     case 4003: error_string="Код ошибки = "+error_code+". Нет памяти для стека функций";                                break;
     case 4004: error_string="Код ошибки = "+error_code+". Переполнение стека после рекурсивного вызова";                break;
     case 4005: error_string="Код ошибки = "+error_code+". На стеке нет памяти для передачи параметров";                 break;
     case 4006: error_string="Код ошибки = "+error_code+". Нет памяти для строкового параметра";                         break;
     case 4007: error_string="Код ошибки = "+error_code+". Нет памяти для временной строки";                             break;
     case 4008: error_string="Код ошибки = "+error_code+". Неинициализированная строка";                                 break;
     case 4009: error_string="Код ошибки = "+error_code+". Неинициализированная строка в массиве";                       break;
     case 4010: error_string="Код ошибки = "+error_code+". Нет памяти для строкового массива";                           break;
     case 4011: error_string="Код ошибки = "+error_code+". Слишком длинная строка";                                      break;
     case 4012: error_string="Код ошибки = "+error_code+". Остаток от деления на ноль";                                  break;
     case 4013: error_string="Код ошибки = "+error_code+". Деление на ноль";                                             break;
     case 4014: error_string="Код ошибки = "+error_code+". Неизвестная команда";                                         break;
     case 4015: error_string="Код ошибки = "+error_code+". Неправильный переход (never generated error)";                break;
     case 4016: error_string="Код ошибки = "+error_code+". Неинициализированный массив";                                 break;
     case 4017: error_string="Код ошибки = "+error_code+". Вызовы DLL не разрешены";                                     break;
     case 4018: error_string="Код ошибки = "+error_code+". Невозможно загрузить библиотеку";                             break;
     case 4019: error_string="Код ошибки = "+error_code+". Невозможно вызвать функцию";                                  break;
     case 4020: error_string="Код ошибки = "+error_code+". Вызовы внешних библиотечных функций не разрешены";            break;
     case 4021: error_string="Код ошибки = "+error_code+". Недостаточно памяти для строки, возвращаемой из функции";     break;
     case 4022: error_string="Код ошибки = "+error_code+". Система занята (never generated error)";                      break;
     case 4050: error_string="Код ошибки = "+error_code+". Неправильное количество параметров функции";                  break;
     case 4051: error_string="Код ошибки = "+error_code+". Недопустимое значение параметра функции";                     break;
     case 4052: error_string="Код ошибки = "+error_code+". Внутренняя ошибка строковой функции";                         break;
     case 4053: error_string="Код ошибки = "+error_code+". Ошибка массива";                                              break;
     case 4054: error_string="Код ошибки = "+error_code+". Неправильное использование массива-таймсерии";                break;
     case 4055: error_string="Код ошибки = "+error_code+". Ошибка пользовательского индикатора";                         break;
     case 4056: error_string="Код ошибки = "+error_code+". Массивы несовместимы";                                        break;
     case 4057: error_string="Код ошибки = "+error_code+". Ошибка обработки глобальныех переменных";                     break;
     case 4058: error_string="Код ошибки = "+error_code+". Глобальная переменная не обнаружена";                         break;
     case 4059: error_string="Код ошибки = "+error_code+". Функция не разрешена в тестовом режиме";                      break;
     case 4060: error_string="Код ошибки = "+error_code+". Функция не подтверждена";                                     break;
     case 4061: error_string="Код ошибки = "+error_code+". Ошибка отправки почты";                                       break;
     case 4062: error_string="Код ошибки = "+error_code+". Ожидается параметр типа string";                              break;
     case 4063: error_string="Код ошибки = "+error_code+". Ожидается параметр типа integer";                             break;
     case 4064: error_string="Код ошибки = "+error_code+". Ожидается параметр типа double";                              break;
     case 4065: error_string="Код ошибки = "+error_code+". В качестве параметра ожидается массив";                       break;
     case 4066: error_string="Код ошибки = "+error_code+". Запрошенные исторические данные в состоянии обновления";      break;
     case 4067: error_string="Код ошибки = "+error_code+". Ошибка при выполнении торговой операции";                     break;
     case 4099: error_string="Код ошибки = "+error_code+". Конец файла";                                                 break;
     case 4100: error_string="Код ошибки = "+error_code+". Ошибка при работе с файлом";                                  break;
     case 4101: error_string="Код ошибки = "+error_code+". Неправильное имя файла";                                      break;
     case 4102: error_string="Код ошибки = "+error_code+". Слишком много открытых файлов";                               break;
     case 4103: error_string="Код ошибки = "+error_code+". Невозможно открыть файл";                                     break;
     case 4104: error_string="Код ошибки = "+error_code+". Несовместимый режим доступа к файлу";                         break;
     case 4105: error_string="Код ошибки = "+error_code+". Ни один ордер не выбран";                                     break;
     case 4106: error_string="Код ошибки = "+error_code+". Неизвестный символ";                                          break;
     case 4107: error_string="Код ошибки = "+error_code+". Неправильный параметр цены для торговой функции";             break;
     case 4108: error_string="Код ошибки = "+error_code+". Неверный номер тикета";                                       break;
     case 4109: error_string="Код ошибки = "+error_code+". Торговля не разрешена";                                       break;
     case 4110: error_string="Код ошибки = "+error_code+". Длинные позиции не разрешены";                                break;
     case 4111: error_string="Код ошибки = "+error_code+". Короткие позиции не разрешены";                               break;
     case 4200: error_string="Код ошибки = "+error_code+". Объект уже существует";                                       break;
     case 4201: error_string="Код ошибки = "+error_code+". Запрошено неизвестное свойство объекта";                      break;
     case 4202: error_string="Код ошибки = "+error_code+". Объект не существует";                                        break;
     case 4203: error_string="Код ошибки = "+error_code+". Неизвестный тип объекта";                                     break;
     case 4204: error_string="Код ошибки = "+error_code+". Нет имени объекта";                                           break;
     case 4205: error_string="Код ошибки = "+error_code+". Ошибка координат объекта";                                    break;
     case 4206: error_string="Код ошибки = "+error_code+". Не найдено указанное подокно";                                break;
     case 4207: error_string="Код ошибки = "+error_code+". Ошибка при работе с объектом";                                break;
     default:   error_string="Код ошибки = "+error_code+". неизвестная ошибка";
    }
//----
  return(error_string);
 }
//+------------------------------------------------------------------+