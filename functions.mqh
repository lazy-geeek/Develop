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

void CalculateHighLow(int lookBackPeriodsHighLow)
  {
   int bars = Bars(_Symbol, _Period);   
   
   // Delete old labels
   ObjectsDeleteAll(ChartID(), "HighLabel_");
   ObjectsDeleteAll(ChartID(), "LowLabel_");
   
   int highIndex = iHighest(_Symbol, _Period, MODE_HIGH, lookBackPeriodsHighLow, 1);
   int lowIndex = iLowest(_Symbol, _Period, MODE_LOW, lookBackPeriodsHighLow, 1);
   
   double lastHigh = iHigh(_Symbol, _Period, highIndex);
   double lastLow = iLow(_Symbol, _Period, lowIndex);
   
   datetime lastHighTime = iTime(_Symbol, _Period, highIndex);
   datetime lastLowTime = iTime(_Symbol, _Period, lowIndex);
   
   string highLabel = "HighLabel_" + TimeToString(lastHighTime);
   string lowLabel = "LowLabel_" + TimeToString(lastLowTime);
   
   CreateLabel(highLabel, lastHighTime, lastHigh, "H", clrLime, 500);
   CreateLabel(lowLabel, lastLowTime, lastLow, "L", clrRed, -500);
  }

//+------------------------------------------------------------------+
//| Calculate Trends Function                                        |
//+------------------------------------------------------------------+
void CalculateTrends(int lookbackBars, int ema1Handle, int ema2Handle, color &candleColorArray[])
  {
   int bars = Bars(_Symbol, _Period);
   if(bars < lookbackBars) return;
   
   ArrayResize(candleColorArray, lookbackBars);
   
   double ema1Buffer[], ema2Buffer[], ema3Buffer[];
   ArraySetAsSeries(ema1Buffer, true);
   ArraySetAsSeries(ema2Buffer, true);
   
   if(CopyBuffer(ema1Handle, 0, 0, lookbackBars, ema1Buffer) != lookbackBars ||
      CopyBuffer(ema2Handle, 0, 0, lookbackBars, ema2Buffer) != lookbackBars)
     {
      Print("Failed to copy EMA data");
      return;
     }
   
   bool isUptrend = false;
   
   for(int i = lookbackBars - 1; i >= 0; i--)
     {
      if(i == lookbackBars - 1)
        {
         isUptrend = (ema1Buffer[i] > ema2Buffer[i]);
        }
      else
        {
         if(ema1Buffer[i] > ema2Buffer[i] && ema1Buffer[i+1] <= ema2Buffer[i+1])
           {
            isUptrend = true;
           }
         else if(ema1Buffer[i] < ema2Buffer[i] && ema1Buffer[i+1] >= ema2Buffer[i+1])
           {
            isUptrend = false;
           }
        }
      
      candleColorArray[i] = isUptrend ? clrGreen : clrRed;
     }
  }

//+------------------------------------------------------------------+
//| Apply Colors Function                                            |
//+------------------------------------------------------------------+
void ApplyColors(int lookbackBars, color &candleColorArray[])
  {
   for(int i = 0; i < lookbackBars; i++)
     {
      datetime time = iTime(_Symbol, _Period, i);
      color candleColor = candleColorArray[i];
      
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
void DrawEMAs(int ema1Handle, int ema2Handle, int ema3Handle, int emaLookbackBars, bool hideEMAs)
  {
   int bars = Bars(_Symbol, _Period);
   int limit = MathMin(bars, emaLookbackBars);
   
   double ema1Buffer[], ema2Buffer[], ema3Buffer[];
   ArraySetAsSeries(ema1Buffer, true);
   ArraySetAsSeries(ema2Buffer, true);
   ArraySetAsSeries(ema3Buffer, true);
   
   if(CopyBuffer(ema1Handle, 0, 0, limit, ema1Buffer) != limit ||
      CopyBuffer(ema2Handle, 0, 0, limit, ema2Buffer) != limit ||
      CopyBuffer(ema3Handle, 0, 0, limit, ema3Buffer) != limit)
     {
      Print("Failed to copy EMA data");
      return;
     }
   
   bool isUptrend = false;
   for(int i = 0; i < limit; i++)
     {
      datetime time = iTime(_Symbol, _Period, i);
      string ema1Name = "EMA1_" + IntegerToString(i);
      string ema2Name = "EMA2_" + IntegerToString(i);
      string ema3Name = "EMA3_" + IntegerToString(i);
      
      if(!hideEMAs)
        {
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
      
      if(i == 0 || i == limit - 1)
        {
         ObjectCreate(ChartID(), ema3Name, OBJ_TREND, 0, time, ema3Buffer[i], time, ema3Buffer[i]);         
        }
      else
        {
         datetime prevTime = iTime(_Symbol, _Period, i + 1);
         ObjectCreate(ChartID(), ema3Name, OBJ_TREND, 0, prevTime, ema3Buffer[i + 1], time, ema3Buffer[i]);
        }
      
      color ema3Color = isUptrend ? clrGreen : clrRed;
      ObjectSetInteger(ChartID(), ema3Name, OBJPROP_COLOR, ema3Color);
      ObjectSetInteger(ChartID(), ema3Name, OBJPROP_WIDTH, 2);
      ObjectSetInteger(ChartID(), ema3Name, OBJPROP_RAY_RIGHT, false);
      
      if(i == 0)
        {
         isUptrend = (ema1Buffer[i] > ema2Buffer[i]);
        }
      else
        {
         if(ema1Buffer[i] > ema2Buffer[i] && ema1Buffer[i-1] <= ema2Buffer[i-1])
           {
            isUptrend = true;
           }
         else if(ema1Buffer[i] < ema2Buffer[i] && ema1Buffer[i-1] >= ema2Buffer[i-1])
           {
            isUptrend = false;
           }
        }
     }
   
   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| Cleanup EMA Objects Function                                     |
//+------------------------------------------------------------------+
void CleanupEMAObjects()
  {
   ObjectsDeleteAll(ChartID(), "EMA1_");
   ObjectsDeleteAll(ChartID(), "EMA2_");
   ObjectsDeleteAll(ChartID(), "EMA3_");
  }

//+------------------------------------------------------------------+
//| Delete Old Labels Function                                       |
//+------------------------------------------------------------------+
void DeleteOldLabels()
  {
   ObjectsDeleteAll(ChartID(), "HighLabel_");
   ObjectsDeleteAll(ChartID(), "LowLabel_");
  }
