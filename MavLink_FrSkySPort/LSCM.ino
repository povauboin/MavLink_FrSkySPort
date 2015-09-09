/* 
 * Wolke lipo-single-cell-monitor
 * *******************************************
 * This will monitor 1 - 8 cells of your lipo.
 * It display the low cell, the high cell and the difference between this cells
 * this will give you a quick overview about your lipo status and if the lipo is well balanced
 *
 * detailed informations and schematics here
 *
 */
#ifdef USE_SINGLE_CELL_MONITOR
/*
 * *******************************************************
 * *** Setup Wolke´ Lipo-Single-Cell-Monitor:          ***
 * *******************************************************
 */
void LSCM_setup()  {
  analogReadResolution(13);
  analogReference(DEFAULT);

  for(int i = 0; i < MAXCELLS; i++){
    zelle[i] = 0;
    cell[i] = 0.0;
    individualcelldivider[i] = LIPOCELL_1TO8[i];
    smoothedVal[i] = 900.0;
  }
}

/*
 * *******************************************************
 * *** Read Data from Lipo-Single-Cell-Network:        ***
 * *******************************************************
 */
void LSCM_process() {
  double aread[MAXCELLS+1];
  for(int i = 0; i < MAXCELLS; i++){
    aread[i] = analogRead(i);
    if(aread[i] < analogread_threshold ){
      cells_in_use = i;
      break;
    } else {
      cells_in_use = MAXCELLS;
    }
    // USE Low Pass filter
    smoothedVal[i] = ( aread[i] * (1 - lp_filter_val)) + (smoothedVal[i]  *  lp_filter_val);
    aread[i] = round(smoothedVal[i]);
    cell[i]  = double (aread[i]/individualcelldivider[i]) * 1000;
    if( i == 0 ) {
      zelle[i] = round(cell[i]);
    } else { 
      zelle[i] = round(cell[i] - cell[i-1]);
    }
  }
  alllipocells = cell[cells_in_use -1];

  #ifdef DEBUG_LIPO_SINGLE_CELL_MONITOR
    //debugSerial.println(aread[0]);
    //debugSerial.println(cell[0]);
    //debugSerial.println("-------");
    debugSerial.print(millis());
    debugSerial.print("\t-\t\t|\tCell 1\t|\tCell 2\t|\tCell3\t|");
    debugSerial.println();
    debugSerial.print(millis());
    debugSerial.print("\t-\t---------------------------------------------------------");
    debugSerial.println();

    debugSerial.print(millis());
    debugSerial.print("\t-\tzelle\t|");
    for(int i = 0; i < MAXCELLS; i++){
      debugSerial.print("\t");
      debugSerial.print(zelle[i]/1000.0);
      debugSerial.print(" V\t|");
    }
    debugSerial.println();
    
    debugSerial.print(millis());
    debugSerial.print("\t-\tcell\t|");
    for(int i = 0; i < MAXCELLS; i++){
      debugSerial.print("\t");
      debugSerial.print(cell[i]/1000);
      debugSerial.print(" V\t|");
    }
    debugSerial.println();
    
    debugSerial.print(millis());
    debugSerial.print("\t-\taread\t|");
    for(int i = 0; i < MAXCELLS; i++){
      debugSerial.print("\t");
      debugSerial.print(aread[i]);
      debugSerial.print("\t|");
    }  
    debugSerial.println();
    
    debugSerial.print(millis());
    debugSerial.print("\t-\t---------------------------------------------------------");
    debugSerial.println();

    debugSerial.print(millis());
    debugSerial.print("\t-\tCells in use: ");
    debugSerial.print(cells_in_use);
    debugSerial.print(" (");
    debugSerial.print(MAXCELLS);
    debugSerial.print(")");
    debugSerial.println();

    debugSerial.print(millis());
    debugSerial.print("\t-\tsum: ");
    debugSerial.print(alllipocells);
    debugSerial.print("mV");
    debugSerial.println();
    debugSerial.println();
  #endif
}
#endif
