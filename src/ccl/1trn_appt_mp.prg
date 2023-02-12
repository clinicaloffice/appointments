/*************************************************************************
 
        Script Name:    1trn_appt_mp.prg
 
        Description:    Clinical Office - mPage Edition
                        Appointment MPage Training Script
 
        Date Written:   January 9, 2023
        Written by:     John Simpson
                        Precision Healthcare Solutions
 
 *************************************************************************
            Copyright (c) 2023 Precision Healthcare Solutions
 
 NO PART OF THIS CODE MAY BE COPIED, MODIFIED OR DISTRIBUTED WITHOUT
 PRIOR WRITTEN CONSENT OF PRECISION HEALTHCARE SOLUTIONS EXECUTIVE
 LEADERSHIP TEAM.
 
 FOR LICENSING TERMS PLEASE VISIT www.clinicaloffice.com/mpage/license
 
 *************************************************************************
                            Special Instructions
 *************************************************************************
 Called from 1co_mpage_entry. Do not attempt to run stand alone. If you
 wish to test the development of your custom script from the CCL back-end,
 please run with 1co_mpage_test.
 
 Possible Payload values:
 
    "customScript": {
        "script": [
            "name": "your custom script name:GROUP1",
            "id": "identifier for your output, omit if you won't be returning data",
            "run": "pre or post",
            "parameters": {
                "your custom parameters for your job"
            }
        ],
        "clearPatientSource": true
    }
 
 *************************************************************************
                            Revision Information
 *************************************************************************
 Rev    Date     By             Comments
 ------ -------- -------------- ------------------------------------------
 001    01/09/23 J. Simpson     Initial Development
 *************************************************************************/
drop program 1trn_appt_mp:group1 go
create program 1trn_appt_mp:group1
 
/*
	The parameters for your script are stored in the PAYLOAD record structure. This
	structure contains the entire payload for the current CCL execution so parameters
	for other Clinical Office jobs may be present (e.g. person, encounter, etc.).
 
	Your payload parameters are stored in payload->customscript->script[script number].parameters.
 
	The script number for your script has been assigned to a variable called nSCRIPT.
 
	For example, if you had a parameter called fromDate in your custom parameters for your script
	you would access it as follows:
 
	set dFromDate = payload->customscript->script[nscript]->parameters.fromdate
 
	**** NOTE ****
	If you plan on running multiple pre/post scripts in the same payload, please ensure that
	you do not have the same parameter with different data types between jobs. For example, if
	you ran two pre/post jobs at the same time with a parameter called fromDate and in one job
	you passed a valid JavaScript date such as  "fromDate": "2018-05-07T14:44:51.000+00:00" and
	in the other job you passed "fromDate": "05-07-2018" the second instance of the parameter
	would cause an error.
*/
 
; Check to see if we have cleared the patient source and if not, do we have data in the patient source
; to run our custom CCL against.
if (validate(payload->customscript->clearpatientsource, 0) = 0)
	if (size(patient_source->patients, 5) = 0)
		go to end_program
	endif
endif
 
; This is the point where you would add your custom CCL code to collect data. If you did not
; choose to clear the patient source, you will have the encounter/person data passed from the
; mpage available for use in the PATIENT_SOURCE record structure.
;
; There are two branches you can use, either VISITS or PATIENTS. The format of the
; record structure is:
;
; 1 patient_source
;	2 visits[*]
;		3 person_id			= f8
;		3 encntr_id			= f8
;	2 patients[*]
;		3 person_id			= f8
;
; Additionally, you can alter the contents of the PATIENT_SOURCE structure to allow encounter
; or person records to be available for standard Clinical Office scripts. For example, your custom
; script may collect a list of visits you wish to have populated in your mPage. Instead of
; manually collecting your demographic information, simply add your person_id/encntr_id combinations
; to the PATIENT_SOURCE record structure and ensure that the standard Clinical Office components
; are being called within your payload. (If this is a little unclear, please see the full
; documentation on http://www.clinicaloffice.com).
 
; ------------------------------------------------------------------------------------------------
;								BEGIN YOUR CUSTOM CODE HERE
; ------------------------------------------------------------------------------------------------
 
; Define the custom record structure you wish to have sent back in the JSON to the mPage. The name
; of the record structure can be anything you want but you must make sure it matches the structure
; name used in the add_custom_output subroutine at the bottom of this script.


; Show incoming parameters
call echorecord(payload->customScript->script[nScript])


free record rParam
record rParam (
    1 dateType              = vc
    1 fromDate              = dq8
    1 toDate                = dq8
    1 appointmentType[*]    = f8
    1 resource[*]           = f8
    1 location[*]           = f8
    1 schState[*]           = f8
)

set stat = cnvtjsontorec(build(^{"rParam":^,payload->customScript->script[nScript].parameters, ^}^), 0, 0, 1)
call echorecord(rParam)

free record rCustom
record rCustom (
    1 appointments[*]
        2 sch_event_id      = f8
        2 encntr_id         = f8
        2 begin_dt_tm       = dq8
        2 duration          = i4
        2 appt_type         = vc
        2 resource          = vc
        2 location          = vc
        2 sch_state         = vc
) 

; Declare parser statements
declare cDateParser = vc with noconstant("1=1")
declare cApptTypeParser = vc with noconstant("1=1")
declare cResourceParser = vc with noconstant("1=1")
declare cLocationParser = vc with noconstant("1=1")
declare cStateParser = vc with noconstant("1=1")

; Build Date parser
if (rParam->dateType = "DATE")      ; Date Range
    set cDateParser = concat(^sa.beg_dt_tm between cnvtdatetime("^, format(rParam->fromDate, "dd-mmm-yyyy;;d"), 
                        ^") and cnvtdatetime("^, format(rParam->toDate, "dd-mmm-yyyy;;d"), ^ 23:59:59")^)
elseif (rParam->dateType != "ALL")  ; 30, 60, 120 days
    set cDateParser = concat(^sa.beg_dt_tm between sysdate and cnvtlookahead("^, rParam->dateType, ^D")^)
endif

declare nNum = i4   ; Needed by the expand statement

; Appointment Type Parser
if (size(rParam->appointmentType, 5) > 0 and rParam->appointmentType[1] != -1)
    set cApptTypeParser = 
        ^expand(nNum, 1, size(rParam->appointmentType, 5), se.appt_type_cd, cnvtreal(rParam->appointmentType[nNum]))^
endif

; Resource Parser
if (size(rParam->resource, 5) > 0 and rParam->resource[1] != -1)
    set cResourceParser = 
        ^expand(nNum, 1, size(rParam->resource, 5), sa2.resource_cd, cnvtreal(rParam->resource[nNum]))^
endif

; State Parser
if (size(rParam->schState, 5) > 0 and rParam->schState[1] != -1)
    set cStateParser = 
        ^expand(nNum, 1, size(rParam->schState, 5), sa.sch_state_cd, cnvtreal(rParam->schState[nNum]))^
endif


; Location Parser
if (size(rParam->location, 5) > 0)
    execute 1co_location_routines:group1 ^"maxViewLevel":"UNIT"^, ^rParam->location^
    set cLocationParser = 
            ^expand(nNum, 1, size(rFilteredLocations->data, 5), sa.appt_location_cd, rFilteredLocations->data[nNum].location_cd)^
endif    
 
; Collect appointments
select into "nl:"
from    sch_appt        sa,
        sch_event       se,
        sch_appt        sa2
plan sa
    where sa.person_id = chart_id->person_id
    and parser(cDateParser)
    and parser(cLocationParser)
    and parser(cStateParser)
    and sa.role_meaning = "PATIENT"
    and sa.state_meaning in ("CONFIRMED", "CHECKED IN", "CHECKED OUT")
    and sa.version_dt_tm > sysdate
    and sa.active_ind = 1
    and sa.end_effective_dt_tm > sysdate
join se
    where se.sch_event_id = sa.sch_event_id
    and parser(cApptTypeParser)
    and se.version_dt_tm > sysdate
    and se.active_ind = 1
    and se.end_effective_dt_tm > sysdate
join sa2
    where sa2.sch_event_id = se.sch_event_id
    and parser(cResourceParser)
    and sa2.role_meaning = "RESOURCE"
    and sa2.state_meaning in ("CONFIRMED", "CHECKED IN", "CHECKED OUT")
    and sa2.version_dt_tm > sysdate
    and sa2.active_ind = 1
    and sa2.end_effective_dt_tm > sysdate
order sa.beg_dt_tm
head report
    nNum = 0
detail
    nNum = nNum + 1
    stat = alterlist(rCustom->appointments, nNum)
    
    rCustom->appointments[nNum].sch_event_id = sa.sch_event_id
    rCustom->appointments[nNum].encntr_id = sa.encntr_id
    rCustom->appointments[nNum].begin_dt_tm = sa.beg_dt_tm
    rCustom->appointments[nNum].duration = sa.duration
    rCustom->appointments[nNum].appt_type = uar_get_code_display(se.appt_type_cd)
    rCustom->appointments[nNum].resource = uar_get_code_display(sa2.resource_cd)
    rCustom->appointments[nNum].location = uar_get_code_display(sa.appt_location_cd)
    rCustom->appointments[nNum].sch_state = uar_get_code_display(sa.sch_state_cd)
with expand=1, counter        
 
; ------------------------------------------------------------------------------------------------
;								END OF YOUR CUSTOM CODE
; ------------------------------------------------------------------------------------------------
 
; If you wish to return output back to the mPage, you need to run the ADD_CUSTOM_OUTPUT function.
; Any valid JSON format is acceptable including the CNVTRECTOJSON function. If using
; CNVTRECTOJSON be sure to use parameters 4 and 1 as shown below.
; If you plan on creating your own JSON string rather than converting a record structure, be
; sure to have it in the format of {"name":{your custom json data}} as the ADD_CUSTOM_OUTPUT
; subroutine will extract the first sub-object from the JSON. (e.g. {"name":{"personId":123}} will
; be sent to the output stream as {"personId": 123}.
call add_custom_output(cnvtrectojson(rCustom, 4, 1))
 
#end_program

 
end go
