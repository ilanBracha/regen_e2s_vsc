#include "new_thread0.h"
#include "app_nfc_reader.h"

/* New Thread entry function */
/* pvParameters contains TaskHandle_t */
void new_thread0_entry(void *pvParameters)
{
    FSP_PARAMETER_NOT_USED (pvParameters);

    /* Start the NFC card reader application.
     * This configures the RS NFC reader and launches the non-blocking NFC
     * event loop (spawns the "RS_NFC" worker task) before returning. */
    app_nfc_reader_entry();

    /* Should not reach here; suspend if it does. */
    vTaskSuspend(NULL);
}
