import pyodbc
import os

dir = os.path.dirname(__file__)

sql_file = open(dir+"\\SQL\\u1_sql_aor_oral_notif", "r")
sql_aor1 = sql_file.readline()
sql_aor2 = sql_file.readline()
sql_oral_notification = sql_file.readline()
sql_file.close()
sql_diagnosis = open(dir+"\\SQL\\sql_diagnosis","r")
sql_dg = sql_diagnosis.read()
sql_diagnosis.close()


def get_db_val(sql):
    # Get values from Configuration file
    server = 'INE1UT-DWDB-001.EHNP.CORP.EVOLENTHEALTH.COM'
    db = 'EVH_DW'
    try:
        conn = pyodbc.connect('Driver={SQL Server};Server=%s;Database=%s;Trusted_Connection=yes;' % (server, db))
        cursor = conn.cursor()
        cursor.execute(sql)
        records = cursor.fetchall()
        return records
    except:
         print("Database Login Error!")
         os._exit(1)
    return 0


def calculate_aor(who_made_the_request, Ref_Nbr):
    aor_date = "NA"
    CareNoteRelatedToKey = []
    CareNoteDateTime = []
    #print(Ref_Nbr)
    #aor_val_from_report = sheet.cell_value(r, 23)  # column id for aor_val_from_report
    if who_made_the_request == 'BR':
        # print(Ref_Nbr)
        # print(who_made_the_request)
        aor_records = get_db_val(sql_aor1.rstrip() + Ref_Nbr + "'")
        for record in aor_records:
            CareNoteRelatedToKey.append(record[2])
            CareNoteDateTime.append(record[1])
        if 8 in CareNoteRelatedToKey and 9 in CareNoteRelatedToKey:
            # print('Both Req and Review')
            aor_records = get_db_val(sql_aor2.rstrip() + Ref_Nbr + "'")
            aor_date = aor_records[0][0].strftime('%Y/%m/%d')
            # print('AOR DATE value is ', aor_date)
        elif 8 in CareNoteRelatedToKey:
            # print('Request Level')
            aor_date = min(CareNoteDateTime).strftime('%Y/%m/%d')
            # print('AOR DATE value is ', aor_date)
        elif 9 in CareNoteRelatedToKey:
            # print('Review Level')
            aor_date = min(CareNoteDateTime).strftime('%Y/%m/%d')
            # print('AOR DATE value is ', aor_date)
    elif who_made_the_request == 'CP' or who_made_the_request == 'NCP' or who_made_the_request == 'B':
        # print('AOR DATE value is NA')
        aor_date = "NA"
    return aor_date


def u2_calculate_aor(who_made_the_request, Ref_Nbr):
    aor_date = []
    CareNoteRelatedToKey = []
    CareNoteDateTime = []
    #print(Ref_Nbr)
    #aor_val_from_report = sheet.cell_value(r, 23)  # column id for aor_val_from_report
    if who_made_the_request == 'BR':
        # print(Ref_Nbr)
        # print(who_made_the_request)
        aor_records = get_db_val(sql_aor1.rstrip() + Ref_Nbr + "'")
        if len(aor_records) == 0:
            aor_date.append("NA")
            aor_date.append("NA")
        for record in aor_records:
            CareNoteRelatedToKey.append(record[2])
            CareNoteDateTime.append(record[1])
        if 8 in CareNoteRelatedToKey and 9 in CareNoteRelatedToKey:
            # print('Both Req and Review')
            aor_records = get_db_val(sql_aor2.rstrip() + Ref_Nbr + "'")
            aor_date.append(aor_records[0][0].strftime('%Y/%m/%d'))
            aor_date.append(aor_records[0][1].strftime('%H:%M:%S'))
            # print('AOR DATE value is ', aor_date)
        elif 8 in CareNoteRelatedToKey:
            # print('Request Level')
            aor_date.append(min(CareNoteDateTime).strftime('%Y/%m/%d'))
            aor_date.append(min(CareNoteDateTime).strftime('%H:%M:%S'))
            # print('AOR DATE value is ', aor_date)
        elif 9 in CareNoteRelatedToKey:
            # print('Review Level')
            aor_date.append(min(CareNoteDateTime).strftime('%Y/%m/%d'))
            aor_date.append(min(CareNoteDateTime).strftime('%H:%M:%S'))
            # print('AOR DATE value is ', aor_date)
    elif who_made_the_request == 'CP' or who_made_the_request == 'NCP' or who_made_the_request == 'B':
        # print('AOR DATE value is NA')
        aor_date.append("NA")
        aor_date.append("NA")
    return aor_date


def calculate_oral_notification(request_disposition_val_from_report,Ref_Nbr):
    db = []
    if request_disposition_val_from_report == 'Approved':
        sql_clause = "' and rldf.AuthReviewUMFinalStatusKey = 3"
    else:
        sql_clause = "' and rldf.AuthReviewUMFinalStatusKey IN (4, 5)"
    #print(sql_oral_notification.rstrip() + str(Ref_Nbr) + sql_clause + " group by A.ReferenceNumber")
    oral_records = get_db_val(sql_oral_notification.rstrip() + str(Ref_Nbr) + sql_clause + " group by A.ReferenceNumber")
    # print(oral_records)
    if len(oral_records) == 0:
        db.append("NA")
    else:
        db.append(oral_records[0][0].strftime('%Y/%m/%d'))
        # print(oral_records[0][0].strftime('%Y/%m/%d'))
    # print(db[0])
    return db[0]


def u2_calculate_oral_notification(request_disposition_val_from_report,Ref_Nbr):
    db = []
    if request_disposition_val_from_report == 'Approved':
        sql_clause = "' and rldf.AuthReviewUMFinalStatusKey = 3"
    else:
        sql_clause = "' and rldf.AuthReviewUMFinalStatusKey IN (4, 5)"
    #print(sql_oral_notification.rstrip() + str(Ref_Nbr) + sql_clause + " group by A.ReferenceNumber")
    oral_records = get_db_val(sql_oral_notification.rstrip() + str(Ref_Nbr) + sql_clause + " group by A.ReferenceNumber")
    if len(oral_records) == 0:
        db.append("NA")
        db.append("NA")
    else:
        db.append(oral_records[0][0].strftime('%Y/%m/%d'))
        db.append(oral_records[0][0].strftime('%H:%M:%S'))
        # print(oral_records[0][0].strftime('%Y/%m/%d'))
    # print(db[0])
    return db


def calculate_diagnosis(RefNo):
    db_giagnosis_codes = get_db_val(sql_dg + str(RefNo) + "' order by df.IsPrimaryDiag desc")
    dg_str = ""
    for d in db_giagnosis_codes:
        dg_str = dg_str + d[0] + " - " + d[1] + "; "
    dg_str = dg_str[:-2]
    dg_str = (dg_str[:100]) if len(dg_str) > 100 else dg_str
    return dg_str
