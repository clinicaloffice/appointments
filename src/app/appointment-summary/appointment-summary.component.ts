import { ChangeDetectionStrategy, ChangeDetectorRef, Component, OnInit, DoCheck } from '@angular/core';
import { AppointmentDataService } from '../appointment-data.service';

@Component({
  selector: 'app-appointment-summary',
  templateUrl: './appointment-summary.component.html',
  styleUrls: ['./appointment-summary.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class AppointmentSummaryComponent implements OnInit, DoCheck {

  constructor(public appointmentDS: AppointmentDataService, public cdr: ChangeDetectorRef) {
  }

  ngOnInit(): void {
  }

  ngDoCheck(): void {
    if (this.appointmentDS.refresh === true) {
      setTimeout(() => {
        this.appointmentDS.refresh = false;
      });
      this.cdr.detectChanges();
    }

  }

}
