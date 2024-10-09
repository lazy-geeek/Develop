// Version number
#property version "1.02"

// Input parameters
input int LookBackPeriods = 100;
input int TrendPeriods = 20;  // New parameter for trend calculation
input int FastEMAPeriod = 14; // Period for fast EMA
input int SlowEMAPeriod = 50; // Period for slow EMA

// Variables
int lastBars = 0;
color candleColors[];
int fastEMAHandle;
int slowEMAHandle;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CalculateLabels();
   CalculateTrends();
   ApplyColors();
   
   // Create EMA indicator handles
   fastEMAHandle = iMA(_Symbol, _Period, FastEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   slowEMAHandle = iMA(_Symbol, _Period, SlowEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   
   if(fastEMAHandle == INVALID_HANDLE || slowEMAHandle == INVALID_HANDLE)
     {
      Print("Failed to create EMA indicators");
      return INIT_FAILED;
     }
   
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
   
   // Release indicator handles
   IndicatorRelease(fastEMAHandle);
   IndicatorRelease(slowEMAHandle);
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
   
   ArrayResize(candleColors, bars);
   
   for(int i = bars - 1; i >= 0; i--)
     {
      double closePrice = iClose(_Symbol, _Period, i);
      
      if(i + TrendPeriods >= bars)
        {
         candleColors[i] = (iOpen(_Symbol, _Period, i) < closePrice) ? clrGreen : clrRed;
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
   int bars = Bars(_Symbol, _Period);
   for(int i = 0; i < bars; i++)
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
//+------------------------------------------------------------------+
//| Draw Moving Averages Function                                    |
//+------------------------------------------------------------------+
void DrawMovingAverages()
  {
   int bars = Bars(_Symbol, _Period);
   double fastEMABuffer[];
   double slowEMABuffer[];
   
   ArraySetAsSeries(fastEMABuffer, true);
   ArraySetAsSeries(slowEMABuffer, true);
   
   CopyBuffer(fastEMAHandle, 0, 0, bars, fastEMABuffer);
   CopyBuffer(slowEMAHandle, 0, 0, bars, slowEMABuffer);
   
   // Create or update Fast EMA line
   ObjectDelete(ChartID(), "FastEMA");
   ObjectCreate(ChartID(), "FastEMA", OBJ_TREND, 0, iTime(_Symbol, _Period, bars-1), fastEMABuffer[bars-1], iTime(_Symbol, _Period, 0), fastEMABuffer[0]);
   ObjectSetInteger(ChartID(), "FastEMA", OBJPROP_COLOR, clrBlue);
   ObjectSetInteger(ChartID(), "FastEMA", OBJPROP_WIDTH, 1);
   ObjectSetInteger(ChartID(), "FastEMA", OBJPROP_RAY_RIGHT, false);
   
   // Create or update Slow EMA line
   ObjectDelete(ChartID(), "SlowEMA");
   ObjectCreate(ChartID(), "SlowEMA", OBJ_TREND, 0, iTime(_Symbol, _Period, bars-1), slowEMABuffer[bars-1], iTime(_Symbol, _Period, 0), slowEMABuffer[0]);
   ObjectSetInteger(ChartID(), "SlowEMA", OBJPROP_COLOR, clrYellow);
   ObjectSetInteger(ChartID(), "SlowEMA", OBJPROP_WIDTH, 1);
   ObjectSetInteger(ChartID(), "SlowEMA", OBJPROP_RAY_RIGHT, false);
   
   ChartRedraw();
  }

void OnTick()
  {
   int currentBars = Bars(_Symbol, _Period);
   if(currentBars > lastBars)
     {
      CalculateLabels();
      CalculateTrends();
      ApplyColors();
     }
   DrawMovingAverages();
   lastBars = currentBars;
  }
//+------------------------------------------------------------------+
