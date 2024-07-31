// Version number
#property version "1.00"

// Input parameter for the number of periods to look back
input int LookBackPeriods = 100;

// Input parameter for the distance between the labels and the candles
input int LabelDistancePoints = 100;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // Delete all graphical objects
   ObjectsDeleteAll(ChartID(), 0, OBJ_TEXT);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   int bars = Bars(_Symbol, _Period);
   if(bars < LookBackPeriods) return;
   
   int highIndex = iHighest(_Symbol, _Period, MODE_HIGH, LookBackPeriods, 1);
   int lowIndex = iLowest(_Symbol, _Period, MODE_LOW, LookBackPeriods, 1);
   
   double lastHigh = iHigh(_Symbol, _Period, highIndex);
   double lastLow = iLow(_Symbol, _Period, lowIndex);
   
   datetime lastHighTime = iTime(_Symbol, _Period, highIndex);
   datetime lastLowTime = iTime(_Symbol, _Period, lowIndex);
   
   string highLabel = "HighLabel_" + TimeToString(lastHighTime);
   if(ObjectFind(ChartID(), highLabel) < 0)
     {
      ObjectCreate(ChartID(), highLabel, OBJ_TEXT, 0, lastHighTime, lastHigh);
      ObjectSetString(ChartID(), highLabel, OBJPROP_TEXT, "H");
      ObjectSetInteger(ChartID(), highLabel, OBJPROP_COLOR, clrLime);
      ObjectSetInteger(ChartID(), highLabel, OBJPROP_FONTSIZE, 12);
      ObjectSetString(ChartID(), highLabel, OBJPROP_FONT, "Arial Bold"); // Set font to bold
     }
   ObjectSetInteger(ChartID(), highLabel, OBJPROP_TIME, lastHighTime);
   ObjectSetDouble(ChartID(), highLabel, OBJPROP_PRICE, lastHigh + _Point * LabelDistancePoints);
   
   string lowLabel = "LowLabel_" + TimeToString(lastLowTime);
   if(ObjectFind(ChartID(), lowLabel) < 0)
     {
      ObjectCreate(ChartID(), lowLabel, OBJ_TEXT, 0, lastLowTime, lastLow);
      ObjectSetString(ChartID(), lowLabel, OBJPROP_TEXT, "L");
      ObjectSetInteger(ChartID(), lowLabel, OBJPROP_COLOR, clrRed);
      ObjectSetInteger(ChartID(), lowLabel, OBJPROP_FONTSIZE, 12);
      ObjectSetString(ChartID(), lowLabel, OBJPROP_FONT, "Arial Bold"); // Set font to bold
     }
   ObjectSetInteger(ChartID(), lowLabel, OBJPROP_TIME, lastLowTime);
   ObjectSetDouble(ChartID(), lowLabel, OBJPROP_PRICE, lastLow - _Point * LabelDistancePoints);
  }
//+------------------------------------------------------------------+
