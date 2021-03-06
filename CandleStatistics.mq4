//+------------------------------------------------------------------+
//|                                             CandleStatistics.mq4 |
//|                                                       Matheszabi |
//|                                         https://www.mathesoft.ro |
//+------------------------------------------------------------------+
#property copyright "Matheszabi"
#property link      "https://www.mathesoft.ro"
#property version   "1.00"
#property description "Candle Statistics."
#property strict
#property indicator_separate_window


#property indicator_color1  Gold   
#property indicator_color2  DodgerBlue  
#property indicator_color3  HotPink 


#property  indicator_buffers 3

double buffTakeProfit[];
double buffMovement[];
double buffStopLoss[];

int candlesInDay;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
//--- indicator buffers mapping
    SetIndexBuffer(0,  buffTakeProfit);
	SetIndexBuffer(1,  buffMovement);
	SetIndexBuffer(2,  buffStopLoss); 

    SetIndexEmptyValue(0 , EMPTY_VALUE);
    SetIndexEmptyValue(1 , EMPTY_VALUE);
    SetIndexEmptyValue(2 , EMPTY_VALUE);
    
    SetIndexStyle(0,  DRAW_HISTOGRAM, STYLE_SOLID,  5, indicator_color1);  
    SetIndexStyle(1,  DRAW_HISTOGRAM, STYLE_SOLID,  2, indicator_color2);  
    SetIndexStyle(2,  DRAW_HISTOGRAM, STYLE_SOLID,  5, indicator_color3);  
    
// -- set a level 0 for stop loss:
    SetLevelValue(0, 0.0);
    
    int timeFrameInMinutes = Period();
    candlesInDay = (int)( (24 * 60) / timeFrameInMinutes);
    ArrayResize(CandleDataArray, candlesInDay);
//---
    return(INIT_SUCCEEDED);
}
  
void OnDeinit(const int reason){
    ArrayFree(CandleDataArray);
}

MqlDateTime dtStruct;
int timeToArrayIndex(datetime candleOpenTime){
   TimeToStruct(candleOpenTime, dtStruct);     
   int candleOpenDailyMinutes = dtStruct.hour * 60 + dtStruct.min;
   // 24*60 ..................... candlesInDay
   // candleOpenDailyMinutes  ... X
   // X = ...
   return (candleOpenDailyMinutes * candlesInDay) / (24*60);
}  

  
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
 {
//---    
    int limit = rates_total - prev_calculated;	
    if(prev_calculated > 0) {
		limit++;
    }
//---   loop collectinig data
    for(int i=limit-1; i>=0  && !IsStopped(); i--){
        int arrayIndex = timeToArrayIndex(Time[i]);
        CandleDataArray[arrayIndex].addCandleData(Open[i], Close[i], Low[i], High[i]);
        
        buffTakeProfit[i] = CandleDataArray[arrayIndex].takeProfit;
        buffMovement[i] = CandleDataArray[arrayIndex].movement;
        buffStopLoss[i] = -CandleDataArray[arrayIndex].stopLoss;
    } 
    
    
//--- return value of prev_calculated for next call
 return(rates_total);
 }
//+------------------------------------------------------------------+


 
 
 
 // Little OOP : it will store the data statistics
 class CandleData
 {
    private:
        //members:
        int dataCount;
        //methods:
        void addTransformedData( double curStopLoss, double curMovement, double curTakeProfit);
        
    public:
        // members:
        int candleOpenTimeMinutes;// the candle opened time
        double stopLoss;
        double movement;
        double takeProfit;
        // constructors:
        CandleData();
        // methods:        
        void addCandleData(double open, double close, double low, double high);
 };
 CandleData::CandleData(){
 }
 
 void CandleData::addTransformedData( double curStopLoss, double curMovement, double curTakeProfit)
 {
    int dataCountPlusOne = this.dataCount +1;
    this.stopLoss   = (this.dataCount * this.stopLoss   + curStopLoss)   / dataCountPlusOne;
    this.movement   = (this.dataCount * this.movement   + curMovement)   / dataCountPlusOne;
    this.takeProfit = (this.dataCount * this.takeProfit + curTakeProfit) / dataCountPlusOne;
    
    this.dataCount = dataCountPlusOne; 
 }
 
 void CandleData::addCandleData( double open, double close, double low, double high){
        
    double curMovement = close-open;// can be exactly 0 too, most cases there is at least 1 point diff
    double curStopLoss, curTakeProfit;
        
    curStopLoss   = curMovement > 0 ? open-low : high-open;
    curTakeProfit = curMovement > 0 ? high-open: open-low;
    curMovement = MathAbs(curMovement);
    
    addTransformedData(curStopLoss, curMovement, curTakeProfit);    
 }
 
 CandleData CandleDataArray[];