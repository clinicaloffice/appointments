/*************************************************************************
 
        Script Name:    1CO_MPAGE_TEST.PRG
 
        Description:    Clinical Office - mPage Edition
        				Back-end payload test utility
 
        Date Written:   March 2, 2018
        Written by:     John Simpson
                        Precision Healthcare Solutions
 
 *************************************************************************
		   Copyright (c) 2022 Precision Healthcare Solutions
 
 NO PART OF THIS CODE MAY BE COPIED, MODIFIED OR DISTRIBUTED WITHOUT
 PRIOR WRITTEN CONSENT OF PRECISION HEALTHCARE SOLUTIONS EXECUTIVE
 LEADERSHIP TEAM.
 
 FOR LICENSING TERMS PLEASE VISIT www.clinicaloffice.com/mpage/license
 
 *************************************************************************
                            Special Instructions
 *************************************************************************
 Used for back-end testing of Clinical Office mPage scripts. You can
 test your own payload JSON by modifying the payload code below.
 *************************************************************************
                            Revision Information
 *************************************************************************
 Rev    Date     By             Comments
 ------ -------- -------------- ------------------------------------------
 001    02/03/18 J. Simpson     Initial Development
 002    11/01/22 J. Simpson     Switched to v3.5 template
 *************************************************************************/
 
drop program 1trn_mp_appointment:group1 go
create program 1trn_mp_appointment:group1
 
prompt
	"Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
	, "FIN" = ""
	, "USERNAME" = ""
 
with outdev, fin, username
 
/* **************************************** */
/* ** DO NOT REMOVE CODE BELOW THIS LINE ** */
/* **************************************** */
 
; Set the absolute maximum possible variable length
SET MODIFY MAXVARLEN 268435456
 
RECORD REQUEST (
	1 BLOB_IN = vc
)
 
; Variable declarations
DECLARE _Memory_Reply_String = vc
DECLARE cvFIN = f8 WITH NOCONSTANT(UAR_GET_CODE_BY("MEANING", 319, "FIN NBR"))
DECLARE nPERSON_ID = f8 with noconstant(0.0)
DECLARE nENCNTR_ID = f8 with noconstant(0.0)
DECLARE nPRSNL_ID = f8 with noconstant(0.0)
 
; Check for a valid FIN. If it does not exist, assume we are running an organizer level mPage
IF (TRIM($FIN) != "")
	; Collect the patient information to pass to the entry mPage
	SELECT INTO "NL:"
		PERSON_ID			= E.PERSON_ID,
		ENCNTR_ID			= E.ENCNTR_ID
	FROM	ENCNTR_ALIAS	EA,
			ENCOUNTER		E
	PLAN EA
		WHERE EA.ALIAS = $FIN
		AND EA.ENCNTR_ALIAS_TYPE_CD = cvFIN
		AND EA.ACTIVE_IND = 1
		AND EA.END_EFFECTIVE_DT_TM > SYSDATE
	JOIN E
		WHERE E.ENCNTR_ID = EA.ENCNTR_ID
	DETAIL
		nPERSON_ID = PERSON_ID
		nENCNTR_ID = ENCNTR_ID
	WITH NOCOUNTER
ENDIF
 
; Collect the PRSNL ID of the current user (or optionally the parameter passed user)
SELECT INTO "NL:"
	USER_SORT			= IF (PR.USERNAME = CURUSER)
							1
						  ENDIF,
	PRSNL_ID			= PR.PERSON_ID
FROM	PRSNL			PR
PLAN PR
	WHERE PR.USERNAME IN (CURUSER, $USERNAME)
	AND PR.ACTIVE_IND = 1
ORDER USER_SORT
HEAD REPORT
	nPRSNL_ID = PRSNL_ID
WITH NOCOUNTER
 
/* **************************************** */
/* ** END OF CODE REMOVAL RESTRICTIONS   ** */
/* **************************************** */
 
; Create your payload here. Format is a simple JSON string in the format of:
; {"payload": { your valid JSON }}
 
set request->BLOB_IN = concat(^{"payload":{"patientSource":[{"personId":0,"encntrId":0}],^,
^"customScript":{"script":[{"name":"1trn_appt_mp:group1","run":"pre","id":"appointments",^,
^"parameters":"{\"dateType\":\"ALL\",\"fromDate\":\"2023-02-11T17:39:31.895Z\",\"toDate\":^,
^\"2023-06-02T17:39:31.895Z\",\"appointmentType\":[],\"resource\":[-1],\"location\":[2600549643],^,
^\"schState\":[4536,4537,4538]}"}]}}}^)
 
call echo(request->BLOB_IN)
 
  
/* **************************************** */
/* ** DO NOT REMOVE CODE BELOW THIS LINE ** */
/* **************************************** */
EXECUTE 1CO3_MPAGE_ENTRY:GROUP1 "MINE", VALUE(nPERSON_ID), VALUE(nENCNTR_ID), VALUE(nPRSNL_ID), 0, ^{"mode":"CHART"}^
 
CALL ECHO(_Memory_Reply_String)
 
END GO
