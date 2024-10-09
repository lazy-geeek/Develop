// Version number
#property version "1.02"

// Input parameters
input int LookBackPeriods = 100;
input int TrendPeriods = 20;  // New parameter for trend calculation

// Variables
int lastBars = 0;
color candleColors[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CalculateLabels();
   CalculateTrends();
   ApplyColors();
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // Delete all graphical objects
   ObjectsDeleteAll(ChartID(), 0, -1);
   
   // Reset chart colors and styles
   ChartSetInteger(ChartID(), CHART_COLOR_CANDLE_BULL, clrWhite);
   ChartSetInteger(ChartID(), CHART_COLOR_CANDLE_BEAR, clrBlack);
   ChartSetInteger(ChartID(), CHART_COLOR_CHART_UP, clrBlack);
   ChartSetInteger(ChartID(), CHART_COLOR_CHART_DOWN, clrBlack);
   ChartSetInteger(ChartID(), CHART_COLOR_CHART_LINE, clrBlack);
   ChartSetInteger(ChartID(), CHART_SHOW_GRID, true);
   ChartSetInteger(ChartID(), CHART_SHOW_VOLUMES, false);
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
      ObjectSetString(ChartID(), labelName, OBJPROP_FONT, "Arial Bold");
     }
   ObjectSetInteger(ChartID(), labelName, OBJPROP_TIME, time);
   ObjectSetDouble(ChartID(), labelName, OBJPROP_PRICE, price + _Point * distancePoints);
  }

//+------------------------------------------------------------------+
//| Calculate Labels Function                                        |
//+------------------------------------------------------------------+
void CalculateLabels()
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
   string lowLabel = "LowLabel_" + TimeToString(lastLowTime);
   
   CreateLabel(highLabel, lastHighTime, lastHigh, "H", clrLime, 500);
   CreateLabel(lowLabel, lastLowTime, lastLow, "L", clrRed, -500);
   
   lastBars = bars;
  }

//+------------------------------------------------------------------+
//| Calculate Trends Function                                        |
//+------------------------------------------------------------------+
void CalculateTrends()
  {
   int bars = Bars(_Symbol, _Period);
   if(bars < LookBackPeriods) return;
   
   ArrayResize(candleColors, LookBackPeriods);
   
   for(int i = LookBackPeriods - 1; i >= 0; i--)
     {
      double openPrice = iOpen(_Symbol, _Period, i);
      double closePrice = iClose(_Symbol, _Period, i);
      
      if(i + TrendPeriods >= LookBackPeriods)
        {
         candleColors[i] = (openPrice < closePrice) ? clrGreen : clrRed;
         continue;
        }
      
      double startPrice = iClose(_Symbol, _Period, i + TrendPeriods);
      candleColors[i] = (startPrice < closePrice) ? clrGreen : clrRed;
     }
  }

//+------------------------------------------------------------------+
//| Apply Colors Function                                            |
//+------------------------------------------------------------------+
void ApplyColors()
  {
   for(int i = 0; i < LookBackPeriods; i++)
     {
      datetime time = iTime(_Symbol, _Period, i);
      color candleColor = candleColors[i];
      
      if(candleColor == clrGreen)
        {
         ChartSetInteger(ChartID(), CHART_COLOR_CANDLE_BULL, clrGreen);
         ChartSetInteger(ChartID(), CHART_COLOR_CHART_UP, clrGreen);
        }
      else
        {
         ChartSetInteger(ChartID(), CHART_COLOR_CANDLE_BEAR, clrRed);
         ChartSetInteger(ChartID(), CHART_COLOR_CHART_DOWN, clrRed);
        }
     }
   ChartRedraw();
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
      CalculateTrends();
      ApplyColors();
     }
  }
//+------------------------------------------------------------------+
