/*
 * Class definition of Wolke lipo-single-cell-monitor
 * *******************************************
 * This will monitor 1 - 8 cells of your lipo.
 * It display the low cell, the high cell and the difference between this cells
 * this will give you a quick overview about your lipo status and if the lipo is well balanced
 *
 * detailed informations and schematics here
 *
 */

#ifndef _LSCM_H_
#define _LSCM_H_

#include "Arduino.h"

class LSCM {

public:
    // ----- Overloaded Constructor -----
    // cells, how many cells connected. analogReadResolution of adac 13 bit on teensy3. smoothness, of low pass filter 0.0001 is max 0.99 is off
    LSCM( uint8_t cells, uint8_t analogReadResolution, float smoothness);
    LSCM( uint8_t cells, uint8_t analogReadResolution);
    LSCM( uint8_t cells);
    
    // ----- LSCM Process -----
    void process();
    
    uint32_t getCellVoltageAsUint32_T(uint8_t cell);
    int32_t getAllLipoCells();
    uint8_t getCellsInUse();
    //uint8_t getMaxCells();
    
    
private:
    
    void initLSCM(uint8_t cells, uint8_t analogReadReso, float smoothness);

    //cell voltage divider. this is dependent from your resitor voltage divider network
    double _LIPOCELL_1TO8[13] =
    {
        1905.331599479, // 277.721518987, //1897.85344189,// 10bit 237.350026082,   3,97
        929.011553273,  // 137.358490566, //926.799312208,// 10bit 116.006256517,   8,03
        615.667808219,  // 91.373534338,  //618.198183455,// 10bit 77.3509473318,  12,04
        0.0, // 470.134166514,// 10bit 58.7966886122,
        0.0, // 370.317778975,// 10bit 46.3358699051,
        0.0, // 315.045617465,// 10bit 39.4176445024,
        0.0, // diverders 7-12 not defined because my network includes only 6 voltage dividers
        0.0,
        0.0,
        0.0,
        0.0,
        0.0
    };
    
    double *_individualcelldivider;
    uint8_t _analogread_threshold;         // threshold for connected zelldetection in mV
    uint8_t _cells_in_use;
    int32_t *_zelle;
    double *_cell;
    int32_t _alllipocells;
    float _lp_filter_val; // this determines smoothness  - .0001 is max  0.99 is off (no smoothing)
    double *_smoothedVal; // this holds the last loop value
    uint8_t _maxcells;
    
    
};
#endif /* _LSCM_H_ */
 
