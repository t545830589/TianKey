from bluetooth import BLE, UUID, advertising
import ubinascii
import utime as time

# Nordic UART Service UUIDs
UART_SERVICE_UUID = UUID('6E400001-B5A3-F393-E0A9-E50E24DCCA9E')
UART_TX_CHAR_UUID = UUID('6E400003-B5A3-F393-E0A9-E50E24DCCA9E')
UART_RX_CHAR_UUID = UUID('6E400002-B5A3-F393-E0A9-E50E24DCCA9E')

class BLE:
    def __init__(self, name):
        self.name = name
        self._ble = BLE()
        self._ble.active(False)
        self._ble.config(gap_name=name)
        self._connected = False
        self._on_connect = None
        self._on_disconnect = None
        self._on_rx = None
        self._conn_handle = None
        self._tx_handle = None
        self._rx_handle = None
        self.scanning = False
        self._services_registered = False

    @property
    def is_connected(self):
        return self._connected

    def start_advertising(self):
        self.scanning = True
        try:
            self._ble.active(True)
            if not self._services_registered:
                self._register_services()
            adv_data = advertising.advertising_payload(
                name=self.name,
                services=[UART_SERVICE_UUID],
                appearance=0x00C0
            )
            scan_rsp = advertising.advertising_payload(name=self.name)
            self._ble.gap_advertise(100 * 1000, adv_data=adv_data, scan_rsp=scan_rsp)
            self._ble.irq(self._irq_handler)
        except Exception as e:
            print('[BLE] 广播启动失败:', e)

    def stop_advertising(self):
        self.scanning = False
        try:
            self._ble.gap_advertise(None)
        except:
            pass

    def _register_services(self):
        try:
            tx_chars = (UART_TX_CHAR_UUID, BLE.CHAR_WRITE | BLE.CHAR_NOTIFY,)
            rx_chars = (UART_RX_CHAR_UUID, BLE.CHAR_WRITE,)
            services = (
                (UART_SERVICE_UUID, (
                    (UART_TX_CHAR_UUID, BLE.CHAR_WRITE | BLE.CHAR_NOTIFY,),
                    (UART_RX_CHAR_UUID, BLE.CHAR_WRITE,),
                )),
            )
            ((self._tx_handle, self._rx_handle),) = self._ble.gatts_register_services(services)
            self._services_registered = True
        except Exception as e:
            print('[BLE] 服务注册失败:', e)

    def _irq_handler(self, event, data):
        if event == 1:  # CONNECT
            self._conn_handle = data[0]
            self._connected = True
            self.scanning = False
            print('[BLE] 设备已连接')
            if self._on_connect:
                self._on_connect()
        elif event == 2:  # DISCONNECT
            self._connected = False
            self._conn_handle = None
            print('[BLE] 设备已断开')
            if self._on_disconnect:
                self._on_disconnect()
        elif event == 3:  # GATTC_WRITE (RX)
            if self._on_rx:
                value = self._ble.gatts_read(self._rx_handle)
                self._on_rx(value)

    def on_connect(self, callback):
        self._on_connect = callback

    def on_disconnect(self, callback):
        self._on_disconnect = callback

    def on_rx(self, callback):
        self._on_rx = callback

    def send(self, data):
        if self._connected and self._tx_handle is not None:
            try:
                self._ble.gatts_notify(self._conn_handle, self._tx_handle, data)
            except Exception as e:
                print('[BLE] 发送失败:', e)
        else:
            print('[BLE] 未连接，无法发送')


class BLEClient:
    def __init__(self, ble):
        self._ble = ble
        self.is_connected = False

    def send(self, data):
        self._ble.send(data)
