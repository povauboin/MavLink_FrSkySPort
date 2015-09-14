/* 
 * Class of Wolke lipo-single-cell-monitor
 * *******************************************
 * This will monitor 1 - 8 cells of your lipo.
 * It display the low cell, the high cell and the difference between this cells
 * this will give you a quick overview about your lipo status and if the lipo is well balanced
 *
 * detailed informations and schematics here
 *
 */

#include "LSCM.h"

// ----- Initialization and Default Values -----
LSCM::LSCM(uint8_t cells)
{
 
  initLSCM(cells, 13, 0.99);    
    
}

LSCM::LSCM(uint8_t cells, uint8_t analogReadReso)
{
  
   initLSCM(cells, analogReadReso, 0.99);   
    
}

LSCM::LSCM(uint8_t cells, uint8_t analogReadReso, float smoothness)
{
  
   initLSCM(cells, analogReadReso, smoothness);
    
}


// public functions
void LSCM::process()
{
  
  double aread[_maxcells+1];
  for(int i = 0; i < _maxcells; i++){
    aread[i] = analogRead(i);
    if(aread[i] < _analogread_threshold ){
      _cells_in_use = i;
      break;
    } else {
      _cells_in_use = _maxcells;
    }
    // USE Low Pass filter
    _smoothedVal[i] = ( aread[i] * (1 - _lp_filter_val)) + (_smoothedVal[i]  *  _lp_filter_val);
    aread[i] = round(_smoothedVal[i]);
    _cell[i]  = double (aread[i]/_individualcelldivider[i]) * 1000;
    if( i == 0 ) {
      _zelle[i] = round(_cell[i]);
    } else { 
      _zelle[i] = round(_cell[i] - _cell[i-1]);
    }
  }
  _alllipocells = _cell[_cells_in_use -1];

  if(_debug){
    //Serial.println(aread[0]);
    //Serial.println(cell[0]);
    //Serial.println("-------");
    Serial.print(millis());
    Serial.print("\t-\t\t|\tCell 1\t|\tCell 2\t|\tCell3\t|");
    Serial.println();
    Serial.print(millis());
    Serial.print("\t-\t---------------------------------------------------------");
    Serial.println();

    Serial.print(millis());
    Serial.print("\t-\tzelle\t|");
    for(int i = 0; i < _maxcells; i++){
      Serial.print("\t");
      Serial.print(_zelle[i]/1000.0);
      Serial.print(" V\t|");
    }
    Serial.println();
    
    Serial.print(millis());
    Serial.print("\t-\tcell\t|");
    for(int i = 0; i < _maxcells; i++){
      Serial.print("\t");
      Serial.print(_cell[i]/1000);
      Serial.print(" V\t|");
    }
    Serial.println();
    
    Serial.print(millis());
    Serial.print("\t-\taread\t|");
    for(int i = 0; i < _maxcells; i++){
      Serial.print("\t");
      Serial.print(aread[i]);
      Serial.print("\t|");
    }  
    Serial.println();
    
    Serial.print(millis());
    Serial.print("\t-\t---------------------------------------------------------");
    Serial.println();

    Serial.print(millis());
    Serial.print("\t-\tCells in use: ");
    Serial.print(_cells_in_use);
    Serial.print(" (");
    Serial.print(_maxcells);
    Serial.print(")");
    Serial.println();

    Serial.print(millis());
    Serial.print("\t-\tsum: ");
    Serial.print(_alllipocells);
    Serial.print("mV");
    Serial.println();
    Serial.println();
  }   
}

uint32_t LSCM::getCellVoltageAsUint32_T(uint8_t cell)
{
    return _zelle[cell];
}

uint8_t LSCM::getCellsInUse()
{
  return _cells_in_use;
}

int32_t LSCM::getAllLipoCells()
{
  return _alllipocells;
}


uint8_t LSCM::getMaxCells()
{
  return _maxcells;
}

void LSCM::setDebug(bool debug)
{
  _debug = debug;
}

void LSCM::setCustomCellDivider(double a)
{
  setCellDivider(a, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
}

void LSCM::setCustomCellDivider(double a, double b)
{
  setCellDivider(a, b, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
}

void LSCM::setCustomCellDivider(double a, double b, double c)
{
  setCellDivider(a, b, c, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
}

void LSCM::setCustomCellDivider(double a, double b, double c, double d)
{
  setCellDivider(a, b, c, d, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
}

void LSCM::setCustomCellDivider(double a, double b, double c, double d, double e)
{
  setCellDivider(a, b, c, d, e, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
}

void LSCM::setCustomCellDivider(double a, double b, double c, double d, double e, double f)
{
  setCellDivider(a, b, c, d, e, f, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
}

void LSCM::setCustomCellDivider(double a, double b, double c, double d, double e, double f,
                                double g)
{
  setCellDivider(a, b, c, d, e, f, g, 0.0, 0.0, 0.0, 0.0, 0.0);
}

void LSCM::setCustomCellDivider(double a, double b, double c, double d, double e, double f,
                                double g, double h)
{
  setCellDivider(a, b, c, d, e, f, g, h, 0.0, 0.0, 0.0, 0.0);
}

void LSCM::setCustomCellDivider(double a, double b, double c, double d, double e, double f,
                                double g, double h, double i)
{
  setCellDivider(a, b, c, d, e, f, g, h, i, 0.0, 0.0, 0.0);
}

void LSCM::setCustomCellDivider(double a, double b, double c, double d, double e, double f,
                                double g, double h, double i, double j)
{
  setCellDivider(a, b, c, d, e, f, g, h, i, j, 0.0, 0.0);
}

void LSCM::setCustomCellDivider(double a, double b, double c, double d, double e, double f,
                                double g, double h, double i, double j, double k)
{
  setCellDivider(a, b, c, d, e, f, g, h, i, j, k, 0.0);
}

void LSCM::setCustomCellDivider(double a, double b, double c, double d, double e, double f,
                                double g, double h, double i, double j, double k, double l)
{
  setCellDivider(a, b, c, d, e, f, g, h, i, j, k, l);
}



// private functions

void LSCM::initLSCM(uint8_t cells, uint8_t analogReadReso, float smoothness)
{
  
  _debug = false;
  _maxcells = cells;
  _cells_in_use = cells;
  _lp_filter_val = smoothness;
  _analogread_threshold = 100;
  _alllipocells = 0;
  analogReadResolution(analogReadReso);
  analogReference(DEFAULT);
  
  _individualcelldivider = new double[cells+1];
  _zelle = new int32_t[cells+1];
  _cell = new double[cells+1];
  _smoothedVal = new double[cells+1];
  
  for(int i = 0; i < cells; i++){
    _zelle[i] = 0;
    _cell[i] = 0.0;
    _individualcelldivider[i] = _LIPOCELL_1TO8[i];
    _smoothedVal[i] = 900.0;
  }
}

void LSCM::setCellDivider(double a, double b, double c, double d, double e, double f,
                          double g, double h, double i, double j, double k, double l)
{
  if(_maxcells < 1) return;
  if(_maxcells < 2) _individualcelldivider[0] = a;
  if(_maxcells < 3) _individualcelldivider[1] = b;
  if(_maxcells < 4) _individualcelldivider[2] = c;
  if(_maxcells < 5) _individualcelldivider[3] = d;
  if(_maxcells < 6) _individualcelldivider[4] = e;
  if(_maxcells < 7) _individualcelldivider[5] = f;
  if(_maxcells < 8) _individualcelldivider[6] = g;
  if(_maxcells < 9) _individualcelldivider[7] = h;
  if(_maxcells < 10) _individualcelldivider[8] = i;
  if(_maxcells < 11) _individualcelldivider[9] = j;
  if(_maxcells < 12) _individualcelldivider[10] = k;
  if(_maxcells < 13) _individualcelldivider[11] = l;  
}

