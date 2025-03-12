import serial
import time

class SerialPort:
    def __init__(self, port, baud_rate=9600, timeout=1):
        """Init serial Port"""
        try:
            self.ser = serial.Serial(
                port=port,
                baudrate=baud_rate,
                bytesize=serial.EIGHTBITS,
                parity=serial.PARITY_NONE,
                stopbits=serial.STOPBITS_ONE,
                timeout=timeout
            )
            print(f"Serial port {port} opened successfully")
        except serial.SerialException as e:
            print(f"Error opening serial port: {e}")
            raise

    def write(self, data):
        """data send: one byte"""
        try:
            byte_data = data.encode()
            self.ser.write(byte_data)  

        except serial.SerialException as e:
            print(f"Error writing to serial port: {e}")

    def read(self, size=1):
        """receive data"""
        try:
            while self.ser.in_waiting == 0:  # wait until received data exist
                pass

            data = self.ser.read(size)  # read one byte
            if data:
                return data  
            
            return ""
        except serial.SerialException as e:
            print(f"Error reading from serial port: {e}")
            return ""

    def close(self):
        """close serial port"""
        if self.ser.is_open:
            self.ser.close()
            print("Serial port closed")

    def __del__(self):
        """Close the port when the object is destroyed."""
        self.close()

def main():
    try:
        # set serial port
        serial_port = SerialPort("COM9", 9600)

        data = "data what u want to send"

        data_len = len(data)

        for char in data:
            serial_port.write(char)

            received = serial_port.read(1)
            if received:
                received = received.decode(errors='ignore')
                print(received, end="")

        print("\n")

        serial_port.close()

    except Exception as e:
        print(f"Exception occurred: {e}")

if __name__ == "__main__":
    main()


