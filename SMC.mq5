#include "functions.mqh"

// Version number
#property version "1.03"

// Input parameters
input int LookBackPeriodsHighLow = 100; // High / Low lookback period
input int EMA1Periods = 50;   // Periods for the first EMA
input int EMA2Periods = 200;  // Periods for the second EMA
input int EMALookbackBars = 5000; // Bars backwards for EMA calculation

// Variables
int lastBars = 0;
color candleColors[];
int EMA1Handle, EMA2Handle;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   DeleteOldLabels();
   CalculateHighLow(LookBackPeriodsHighLow);
   
   // Initialize EMA handles and draw EMAs
   EMA1Handle = iMA(_Symbol, _Period, EMA1Periods, 0, MODE_EMA, PRICE_CLOSE);
   EMA2Handle = iMA(_Symbol, _Period, EMA2Periods, 0, MODE_EMA, PRICE_CLOSE);
   
   if(EMA1Handle == INVALID_HANDLE || EMA2Handle == INVALID_HANDLE)
     {
      Print("Failed to create EMA indicators");
      return(INIT_FAILED);
     }
   
   CalculateTrends(EMALookbackBars, EMA1Handle, EMA2Handle, candleColors);
   ApplyColors(EMALookbackBars, candleColors);
   
   CleanupEMAObjects();
   DrawEMAs(EMA1Handle, EMA2Handle, EMALookbackBars);
   
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
   
   // Delete candle and border objects
   ObjectsDeleteAll(ChartID(), "Candle_");
   ObjectsDeleteAll(ChartID(), "CandleBorder_");
   
   // Release EMA indicator handles
   IndicatorRelease(EMA1Handle);
   IndicatorRelease(EMA2Handle);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   int currentBars = Bars(_Symbol, _Period);
   if(currentBars > lastBars)
     {
      DeleteOldLabels();
      CalculateHighLow(LookBackPeriodsHighLow);
      CalculateTrends(EMALookbackBars, EMA1Handle, EMA2Handle, candleColors);
      ApplyColors(EMALookbackBars, candleColors);
      CleanupEMAObjects();
      DrawEMAs(EMA1Handle, EMA2Handle, EMALookbackBars);
     }   
   
   lastBars = currentBars;
  }
//+------------------------------------------------------------------+
