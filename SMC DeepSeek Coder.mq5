// Version number
#property version "1.00"

// Input parameter for the number of periods to look back
input int LookBackPeriods = 100;

// Variable to store the last known number of bars
int lastBars = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CalculateLabels();
   CreateTrendRectangle();
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // Delete all graphical objects
   ObjectsDeleteAll(ChartID(), 0, OBJ_TEXT);
   ObjectsDeleteAll(ChartID(), 0, OBJ_RECTANGLE_LABEL);
  }
//+------------------------------------------------------------------+
//| Create Label Function                                            |
//+------------------------------------------------------------------+
void CreateLabel(string labelName, datetime time, double price, string text, color labelColor, int distancePoints)
  {
   if(ObjectFind(ChartID(), labelName) < 0)
     {
      ObjectCreate(ChartID(), labelName, OBJ_TEXT, 0, time, price);
      ObjectSetString(ChartID(), labelName, OBJPROP_TEXT, text);
      ObjectSetInteger(ChartID(), labelName, OBJPROP_COLOR, labelColor);
      ObjectSetInteger(ChartID(), labelName, OBJPROP_FONTSIZE, 12);
      ObjectSetString(ChartID(), labelName, OBJPROP_FONT, "Arial Bold"); // Set font to bold
     }
   ObjectSetInteger(ChartID(), labelName, OBJPROP_TIME, time);
   ObjectSetDouble(ChartID(), labelName, OBJPROP_PRICE, price + _Point * distancePoints);
  }
//+------------------------------------------------------------------+
//| Calculate Labels Function                                        |
//+------------------------------------------------------------------+
void CalculateLabels()
  {
   // Delete old labels

   ObjectsDeleteAll(ChartID(), 0, OBJ_TEXT);

   int bars = Bars(_Symbol, _Period);
   if(bars < LookBackPeriods) return;
   
   int highIndex = iHighest(_Symbol, _Period, MODE_HIGH, LookBackPeriods, 1);
   int lowIndex = iLowest(_Symbol, _Period, MODE_LOW, LookBackPeriods, 1);
   
   double lastHigh = iHigh(_Symbol, _Period, highIndex);
   double lastLow = iLow(_Symbol, _Period, lowIndex);
   
   datetime lastHighTime = iTime(_Symbol, _Period, highIndex);
   datetime lastLowTime = iTime(_Symbol, _Period, lowIndex);
   
   string highLabel = "HighLabel_" + TimeToString(lastHighTime);
   string lowLabel = "LowLabel_" + TimeToString(lastLowTime);
   
   CreateLabel(highLabel, lastHighTime, lastHigh, "H", clrLime, 500); // High label distance
   CreateLabel(lowLabel, lastLowTime, lastLow, "L", clrRed, -500); // Low label distance
   
   lastBars = bars;
  }
//+------------------------------------------------------------------+
//| Create Trend Rectangle Function                                  |
//+------------------------------------------------------------------+
void CreateTrendRectangle()
  {
   string rectName = "TrendRectangle";
   if(ObjectFind(ChartID(), rectName) < 0)
     {
      ObjectCreate(ChartID(), rectName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(ChartID(), rectName, OBJPROP_XDISTANCE, 0);
      ObjectSetInteger(ChartID(), rectName, OBJPROP_YDISTANCE, 20);
      ObjectSetInteger(ChartID(), rectName, OBJPROP_XSIZE, ChartGetInteger(ChartID(), CHART_WIDTH_IN_PIXELS));
      ObjectSetInteger(ChartID(), rectName, OBJPROP_YSIZE, 20);
      ObjectSetInteger(ChartID(), rectName, OBJPROP_BGCOLOR, clrGreen);
      ObjectSetInteger(ChartID(), rectName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(ChartID(), rectName, OBJPROP_COLOR, clrBlack);
      ObjectSetInteger(ChartID(), rectName, OBJPROP_WIDTH, 1);
      ObjectSetInteger(ChartID(), rectName, OBJPROP_CORNER, CORNER_LEFT_LOWER);
      ObjectSetInteger(ChartID(), rectName, OBJPROP_BACK, false);
      ObjectSetInteger(ChartID(), rectName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(ChartID(), rectName, OBJPROP_SELECTED, false);
     }
  }
//+------------------------------------------------------------------+
//| Update Trend Rectangle Function                                  |
//+------------------------------------------------------------------+
void UpdateTrendRectangle(bool uptrend)
  {
   string rectName = "TrendRectangle";
   if(ObjectFind(ChartID(), rectName) >= 0)
     {
      ObjectSetInteger(ChartID(), rectName, OBJPROP_BGCOLOR, uptrend ? clrGreen : clrRed);
     }
  }
//+------------------------------------------------------------------+
//| Check Trend Function                                             |
//+------------------------------------------------------------------+
bool CheckTrend()
  {
   int bars = Bars(_Symbol, _Period);
   if(bars < 3) return false;
   
   double lastHigh = iHigh(_Symbol, _Period, 1);
   double prevHigh = iHigh(_Symbol, _Period, 2);
   double lastLow = iLow(_Symbol, _Period, 1);
   double prevLow = iLow(_Symbol, _Period, 2);
   
   bool uptrend = (lastHigh > prevHigh) && (lastLow > prevLow);
   bool downtrend = (lastHigh < prevHigh) && (lastLow < prevLow);
   
   if(uptrend || downtrend)
     {
      UpdateTrendRectangle(uptrend);
      return true;
     }
   return false;
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   int currentBars = Bars(_Symbol, _Period);
   if(currentBars > lastBars)
     {
      CalculateLabels();
      CheckTrend();
     }
  }
