import { TestBed } from '@angular/core/testing';

import { AppointmentDataService } from './appointment-data.service';

describe('AppointmentDataService', () => {
  let service: AppointmentDataService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(AppointmentDataService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
