import { Injectable } from '@angular/core';
import { CustomService, IColumnConfig } from '@clinicaloffice/clinical-office-mpage';
import { MatSnackBar } from '@angular/material/snack-bar';

@Injectable({
  providedIn: 'root'
})
export class AppointmentDataService {
  public loading = false;
  public refresh = false;
  public columnConfig: IColumnConfig = {columns: [], columnSort: [], freezeLeft: 0};
  public prompts = this.emptyPrompts;

  constructor(public customService: CustomService, private snackBar: MatSnackBar) { }

  public loadAppointments(): void {

    this.loading = true;

    this.customService.load({
      customScript: {
        script: [
          {
            name: '1trn_appt_mp:group1',
            run: 'pre',
            id: 'appointments',
            parameters: JSON.stringify(this.prompts)
          }
        ]
      }
    }, undefined, (() => { 
      this.loading = false; 
      this.refresh = true;
    }));

  }

  // Returns the appointments data
  public get appointments(): any[] {
    return this.customService.get('appointments').appointments;
  }

  // Determine if appointments have been loaded
  public get appointmentsLoaded(): boolean {
    return this.customService.isLoaded('appointments');
  }

  // Save user preferences
  public savePreferences(): void {

    this.customService.executeDmInfoAction('saveUserPrefs', 'w', [
      {
        infoDomain: '1trn_appt_mp',
        infoName: 'column_prefs',
        infoDate: new Date(),
        infoChar: '',
        infoNumber: 0,
        infoLongText: JSON.stringify({
          columnConfig: this.columnConfig,
          prompts: this.prompts
        }),
        infoDomainId: this.customService.mpage.prsnlId
      }
    ], () => {
      this.snackBar.open('Saved Preferences.', 'Ok', {duration: 1000});
    });

  }

  // Load user preferences
  public loadPreferences(): void {
    this.loading = true;
    
    const prefMessage = this.customService.emptyDmInfo;
    prefMessage.infoDomain = '1trn_appt_mp';
    prefMessage.infoName = 'column_prefs';
    prefMessage.infoDomainId = this.customService.mpage.prsnlId

    this.customService.executeDmInfoAction('userPrefs', 'r', [ prefMessage ], () => {

      // Check for user preferences and assign them
      if (this.customService.isLoaded('userPrefs')) {
        const config = JSON.parse(this.customService.get('userPrefs').dmInfo[0].longText);
        this.columnConfig = config.columnConfig ?? this.columnConfig;        
        this.prompts = config.prompts ?? this.prompts;

        // Default the dates to today
        this.prompts.fromDate = new Date();
        this.prompts.toDate = new Date();
      }

      this.loadAppointments();
    });
  }

  // Empty Prompts
  public get emptyPrompts(): any {
    return ({
      dateType: '30',
      fromDate: new Date(),
      toDate: new Date(),
      appointmentType: [],
      resource: [],
      location: [],
      schState: []
    });   
  }

  // Clear prompt values
  public clearPrompts(): void {
    this.prompts = this.emptyPrompts;
  }

}
