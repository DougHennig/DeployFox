#include VFPXBaseLibrary.h

* Registry constants.

#define cnSUCCESS                    0
#define cnERROR_EOF 			     259
	* no more entries in key
#define cnRESERVED                   0
#define cnBUFFER_SIZE                256
	* the size of the buffer for the key value

* Registry key values.

#define cnHKEY_CLASSES_ROOT          -2147483648
#define cnHKEY_CURRENT_USER          -2147483647
#define cnHKEY_LOCAL_MACHINE         -2147483646
#define cnHKEY_USERS                 -2147483645

* Data types.

#define cnREG_SZ                     1	&& String
#define cnREG_EXPAND_SZ              2	&& String containing unexpanded references to environment variables
#define cnREG_BINARY                 3	&& Binary
#define cnREG_DWORD                  4	&& 32-bit number
#define cnREG_MULTI_SZ               7	&& Multi-value

* Restrictions.

#define cnRRF_RT_ANY				 0x0000ffff		&& no data type restriction
#define cnRRF_SUBKEY_WOW6464KEY		 0x00010000
#define cnRRF_SUBKEY_WOW6432KEY		 0x00020000		

* ODBC constants.

#define ccODBC_DATA_KEY              'Software\ODBC\ODBC.INI\'
#define ccODBC_DRVRS_KEY             'Software\ODBC\ODBCINST.INI\'
#define cnSQL_FETCH_NEXT             1
#define cnSQL_NO_DATA			     100
#define cnSQL_SUCCESS_WITH_INFO      1
#define cnSQL_CHAR                   1
#define cnSTR_LEN                    254
#define cnSQL_HANDLE_DBC             2
#define cnSQL_HANDLE_STMT            3

* SQLConfigureDataSource API constants.

#define cnODBC_ADD_DSN               1
#define cnODBC_CONFIG_DSN            2
#define cnODBC_REMOVE_DSN            3
#define cnODBC_ADD_SYS_DSN           4
#define cnODBC_CONFIG_SYS_DSN        5
#define cnODBC_REMOVE_SYS_DSN        6
#define cnODBC_REMOVE_DEFAULT_DSN    7
