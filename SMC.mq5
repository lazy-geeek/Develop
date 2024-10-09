// Version number
#property version "1.02"

// Input parameters
input int LookBackPeriods = 100;
input int TrendPeriods = 20;  // New parameter for trend calculation
input int EMAPeriod1 = 12;    // New parameter for the first EMA
input int EMAPeriod2 = 26;    // New parameter for the second EMA

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
   DrawEMAs();  // Call function to draw EMAs
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
//| Draw EMAs Function                                               |
//+------------------------------------------------------------------+
void DrawEMAs()
  {
   int bars = Bars(_Symbol, _Period);
   double ema1[], ema2[];
   
   ArraySetAsSeries(ema1, true);
   ArraySetAsSeries(ema2, true);
   
   if(CopyBuffer(iMA(_Symbol, _Period, EMAPeriod1, 0, MODE_EMA, PRICE_CLOSE), 0, 0, bars, ema1) <= 0) return;
   if(CopyBuffer(iMA(_Symbol, _Period, EMAPeriod2, 0, MODE_EMA, PRICE_CLOSE), 0, 0, bars, ema2) <= 0) return;
   
   for(int i = 0; i < bars; i++)
     {
      string ema1Name = "EMA1_" + IntegerToString(i);
      string ema2Name = "EMA2_" + IntegerToString(i);
      
      if(ObjectFind(ChartID(), ema1Name) < 0)
        {
         ObjectCreate(ChartID(), ema1Name, OBJ_TREND, 0, iTime(_Symbol, _Period, i), ema1[i]);
         ObjectSetInteger(ChartID(), ema1Name, OBJPROP_COLOR, clrBlue);
         ObjectSetInteger(ChartID(), ema1Name, OBJPROP_WIDTH, 2); // Set line width
        }
      else
        {
         ObjectMove(ChartID(), ema1Name, 0, iTime(_Symbol, _Period, i), ema1[i]);
        }
      
      if(ObjectFind(ChartID(), ema2Name) < 0)
        {
         ObjectCreate(ChartID(), ema2Name, OBJ_TREND, 0, iTime(_Symbol, _Period, i), ema2[i]);
         ObjectSetInteger(ChartID(), ema2Name, OBJPROP_COLOR, clrYellow);
         ObjectSetInteger(ChartID(), ema2Name, OBJPROP_WIDTH, 2); // Set line width
        }
      else
        {
         ObjectMove(ChartID(), ema2Name, 0, iTime(_Symbol, _Period, i), ema2[i]);
        }
     }
   ChartRedraw(); // Ensure the chart is redrawn
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
      DrawEMAs();  // Update EMAs on each tick
     }
  }
//+------------------------------------------------------------------+
