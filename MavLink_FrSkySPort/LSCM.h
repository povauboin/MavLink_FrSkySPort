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
    
    /**
    \ingroup MavLink_FrSkySPort
    \brief Overloaded Constructor of LSCM Object
    \descriptions construct LSCM minimal with cells count.
    \example LSCM lscm(false, 3, 13, 0.99);
    \args
    \cells how many cells connected
    \analogReadResolution on teensy3.x 13 bit as default
    \smoothness value of low pass filtering, 0.0001 is max 0.99 is off (default)
    */
    LSCM(uint8_t cells, uint8_t analogReadResolution, float smoothness);
    LSCM(uint8_t cells, uint8_t analogReadResolution);
    LSCM(uint8_t cells);
    
    /**
    \brief main-process-call of LSCM. 
    \descriptions: must called in main loop.
    */
    void process();
    
    /**
    \brief returns disered Cell voltage 0-n based on lipocells. 
    \descriptions returned an uint32_t of called lipocell.
    */   
    uint32_t getCellVoltageAsUint32_T(uint8_t cell);

    /**
    \brief returns Cell voltage sum from al Cells. 
    \descriptions returned an int32_t Cell sum.
    */ 
    int32_t getAllLipoCells();
    
    /**
    \brief returns quantity of really connected cells. 
    \descriptions returned an uint8_t of real connected cells.
    */ 
    uint8_t getCellsInUse();
    
    /**
    \brief quantity of cells at init. 
    \descriptions returned an uint8_t of real connected cells.
    */
    uint8_t getMaxCells();
    
    /**
    \brief debug. 
    \descriptions enable disable debug.
    */
    void setDebug(bool debug);
    
    
private:
    
    /**
    \descriptions init LSCM object variables and arrays. automatically called by constructor
    */
    void initLSCM(uint8_t cells, uint8_t analogReadReso, float smoothness);

    
    
    /**
    \brief main Array which holds software deviders. 
    \descriptions this divider are used if LSCM object will init. Users need to adjust this values
    \descriptions in dependecy to their resistor network 
    */
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
    
    bool _debug;
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
 
