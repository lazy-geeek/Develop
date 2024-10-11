// Version number
#property version "1.02"

// Input parameters
input int LookBackPeriods = 100; // High / Low lookback period
input int TrendPeriods = 20;  // New parameter for trend calculation
input int EMA1Periods = 50;   // Periods for the first EMA
input int EMA2Periods = 200;  // Periods for the second EMA
input int EMALookbackBars = 500; // Bars backwards for EMA calculation

// Variables
int lastBars = 0;
color candleColors[];
int EMA1Handle, EMA2Handle;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CalculateLabels();
   CalculateTrends();
   ApplyColors();
   
   // Initialize EMA handles and draw EMAs
   EMA1Handle = iMA(_Symbol, _Period, EMA1Periods, 0, MODE_EMA, PRICE_CLOSE);
   EMA2Handle = iMA(_Symbol, _Period, EMA2Periods, 0, MODE_EMA, PRICE_CLOSE);
   
   if(EMA1Handle == INVALID_HANDLE || EMA2Handle == INVALID_HANDLE)
     {
      Print("Failed to create EMA indicators");
      return(INIT_FAILED);
     }
   
   CleanupEMAObjects();
   DrawEMAs();
   
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
   
   // Release EMA indicator handles
   IndicatorRelease(EMA1Handle);
   IndicatorRelease(EMA2Handle);
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
//| Draw EMAs Function                                               |
//+------------------------------------------------------------------+
void DrawEMAs()
  {
   int bars = Bars(_Symbol, _Period);
   int limit = MathMin(bars, EMALookbackBars);
   
   double ema1Buffer[], ema2Buffer[];
   ArraySetAsSeries(ema1Buffer, true);
   ArraySetAsSeries(ema2Buffer, true);
   
   // Recalculate EMA values
   IndicatorRelease(EMA1Handle);
   IndicatorRelease(EMA2Handle);
   EMA1Handle = iMA(_Symbol, _Period, EMA1Periods, 0, MODE_EMA, PRICE_CLOSE);
   EMA2Handle = iMA(_Symbol, _Period, EMA2Periods, 0, MODE_EMA, PRICE_CLOSE);
   
   if(EMA1Handle == INVALID_HANDLE || EMA2Handle == INVALID_HANDLE)
     {
      Print("Failed to create EMA indicators");
      return;
     }
   
   if(CopyBuffer(EMA1Handle, 0, 0, limit, ema1Buffer) != limit ||
      CopyBuffer(EMA2Handle, 0, 0, limit, ema2Buffer) != limit)
     {
      Print("Failed to copy EMA data");
      return;
     }
   
   for(int i = 0; i < limit; i++)
     {
      datetime time = iTime(_Symbol, _Period, i);
      string ema1Name = "EMA1_" + IntegerToString(i);
      string ema2Name = "EMA2_" + IntegerToString(i);
      
      if(i == 0 || i == limit - 1)
        {
         ObjectCreate(ChartID(), ema1Name, OBJ_TREND, 0, time, ema1Buffer[i], time, ema1Buffer[i]);
         ObjectCreate(ChartID(), ema2Name, OBJ_TREND, 0, time, ema2Buffer[i], time, ema2Buffer[i]);
        }
      else
        {
         datetime prevTime = iTime(_Symbol, _Period, i + 1);
         ObjectCreate(ChartID(), ema1Name, OBJ_TREND, 0, prevTime, ema1Buffer[i + 1], time, ema1Buffer[i]);
         ObjectCreate(ChartID(), ema2Name, OBJ_TREND, 0, prevTime, ema2Buffer[i + 1], time, ema2Buffer[i]);
        }
      
      ObjectSetInteger(ChartID(), ema1Name, OBJPROP_COLOR, clrBlue);
      ObjectSetInteger(ChartID(), ema1Name, OBJPROP_WIDTH, 2);
      ObjectSetInteger(ChartID(), ema1Name, OBJPROP_RAY_RIGHT, false);
      
      ObjectSetInteger(ChartID(), ema2Name, OBJPROP_COLOR, clrYellow);
      ObjectSetInteger(ChartID(), ema2Name, OBJPROP_WIDTH, 2);
      ObjectSetInteger(ChartID(), ema2Name, OBJPROP_RAY_RIGHT, false);
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
      CleanupEMAObjects();
      DrawEMAs();
     }   
   
   lastBars = currentBars;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Cleanup EMA Objects Function                                     |
//+------------------------------------------------------------------+
void CleanupEMAObjects()
  {
   ObjectsDeleteAll(ChartID(), "EMA1_");
   ObjectsDeleteAll(ChartID(), "EMA2_");
  }
//+------------------------------------------------------------------+
