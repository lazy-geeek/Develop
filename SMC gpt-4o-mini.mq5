//+------------------------------------------------------------------+
//|                                                      MyEA.mq5    |
//|                        Copyright 2023, MetaQuotes Software Corp. |
//|                                                                  |
//+------------------------------------------------------------------+
input int LookBackPeriod = 20;  // Number of candles to look back for highs and lows
string highLabel = "HighLabel";
string lowLabel = "LowLabel";
color highColor = clrRed;
color lowColor = clrGreen;
//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit() 
{
    return INIT_SUCCEEDED;
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) 
{
    ObjectDelete(0, highLabel);
    ObjectDelete(0, lowLabel);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() 
{
    double lastHigh = iHigh(Symbol(), 0, 1);
    double lastLow = iLow(Symbol(), 0, 1);
    long lastHighTime = iTime(Symbol(), 0, iBarShift(Symbol(), 0, lastHigh)); // Get the timestamp of last high
    long lastLowTime = iTime(Symbol(), 0, iBarShift(Symbol(), 0, lastLow));   // Get the timestamp of last low
    // Loop through the last 'LookBackPeriod' candles to find the highest and lowest
    for (int i = 1; i < LookBackPeriod; i++) 
    {
        if (iHigh(Symbol(), 0, i) > lastHigh) 
        {
            lastHigh = iHigh(Symbol(), 0, i);
            lastHighTime = iTime(Symbol(), 0, i); // Update the time
        }
        if (iLow(Symbol(), 0, i) < lastLow) 
        {
            lastLow = iLow(Symbol(), 0, i);
            lastLowTime = iTime(Symbol(), 0, i); // Update the time
        }
    }

    Print("Last High: ", lastHigh, " Last Low: ", lastLow);
    // Create or update the high label
    CreateOrUpdateLabel(highLabel, "H", lastHigh + (10 * _Point), highColor, lastHighTime);
    // Create or update the low label
    CreateOrUpdateLabel(lowLabel, "L", lastLow - (10 * _Point), lowColor, lastLowTime);
}
//+------------------------------------------------------------------+
//| Create or update a label at the given price level               |
//+------------------------------------------------------------------+
void CreateOrUpdateLabel(string labelName, string text, double price, color labelColor, long time) 
{
    if(ObjectFind(0, labelName) == -1) // Check if the label exists; if not, create it
    {
        if(ObjectCreate(0, labelName, OBJ_LABEL, 0, 0, 0)) 
        {
            ObjectSetInteger(0, labelName, OBJPROP_COLOR, labelColor);
            ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 10);
            Print("Label created: ", labelName);
        } 
        else 
        {
            Print("Error creating label: ", GetLastError());
            return; // Exit if label creation fails
        }
    } 
    else 
    {
        Print("Updating label: ", labelName);
    }
    // Set the label properties correctly
    ObjectSetDouble(0, labelName, OBJPROP_PRICE, price); // Ensure price is a double.
    
    // Use explicit values for Y distance
    double yDistance = (text == "H") ? 20.0 : -20.0; // Define as a double
    ObjectSetDouble(0, labelName, OBJPROP_YDISTANCE, yDistance); // Set Y distance correctly.
    ObjectSetInteger(0, labelName, OBJPROP_XDISTANCE, 0); // Set X distance (integer).

    ObjectSetString(0, labelName, OBJPROP_TEXT, text); // Set the text for the label
}

//+------------------------------------------------------------------+
