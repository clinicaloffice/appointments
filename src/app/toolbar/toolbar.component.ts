import { Component, OnInit, ChangeDetectionStrategy, ChangeDetectorRef, DoCheck } from '@angular/core';
import { AppointmentDataService } from '../appointment-data.service';

@Component({
  selector: 'app-toolbar',
  templateUrl: './toolbar.component.html',
  styleUrls: ['./toolbar.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class ToolbarComponent implements OnInit, DoCheck {
  public dateTypes = [
    { key: '30', value: '30 Days' },
    { key: '60', value: '60 Days' },
    { key: '120', value: '120 Days' },
    { key: 'DATE', value: 'Date Range' },
    { key: 'ALL', value: 'All Dates' }
  ];

  constructor(public appointmentDS: AppointmentDataService, public cdr: ChangeDetectorRef) { }

  ngOnInit(): void {
  }

  ngDoCheck(): void {
      if (this.appointmentDS.refresh === true) {
        this.cdr.detectChanges();
      }
  }
}
