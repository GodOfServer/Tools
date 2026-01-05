import os
import sys

def format_number(num):
    """Format angka dengan titik pemisah ribuan"""
    return f"{num:,}".replace(",", ".")

def main():
    print("=" * 50)
    print("FILE LIST SPLITTER")
    print("=" * 50)
    
    # Input file list
    input_file = input("[ + ] Masukkan File List: ").strip()
    
    # Validasi file
    if not os.path.exists(input_file):
        print(f"[ ! ] File '{input_file}' tidak ditemukan!")
        sys.exit(1)
    
    # Input jumlah list per file
    lines_per_file_input = input("[ + ] Jumlah list per file (contoh: 1.000.000): ").strip()
    
    # Hapus titik dari input
    lines_per_file_input = lines_per_file_input.replace(".", "")
    
    try:
        lines_per_file = int(lines_per_file_input)
        if lines_per_file <= 0:
            raise ValueError
    except ValueError:
        print("[ ! ] Input tidak valid! Masukkan angka yang valid.")
        sys.exit(1)
    
    # Input nama file deploy
    output_name = input("[ + ] Nama File Deploy: ").strip()
    
    # Hapus ekstensi jika ada
    if output_name.endswith('.txt'):
        output_name = output_name[:-4]
    
    print("\n[ + ] Proccess . . . \n")
    
    # Proses pemecahan file
    try:
        file_count = 1
        line_count = 0
        current_file = None
        
        # Hitung total baris dulu untuk progress
        print("[ + ] Menghitung total baris...")
        with open(input_file, 'r', encoding='utf-8', errors='ignore') as f:
            total_lines = sum(1 for _ in f)
        
        print(f"[ + ] Total baris: {format_number(total_lines)}")
        
        # Buka file input lagi untuk diproses
        with open(input_file, 'r', encoding='utf-8', errors='ignore') as f:
            for i, line in enumerate(f, 1):
                # Buka file baru setiap lines_per_file
                if line_count % lines_per_file == 0:
                    if current_file:
                        current_file.close()
                    
                    # Buat nama file baru
                    output_filename = f"{output_name}-{file_count}.txt"
                    current_file = open(output_filename, 'w', encoding='utf-8')
                    print(f"[ + ] Membuat file: {output_filename}")
                    file_count += 1
                
                # Tulis baris ke file
                current_file.write(line)
                line_count += 1
                
                # Tampilkan progress setiap 100.000 baris
                if i % 100000 == 0:
                    print(f"[ + ] Diproses: {format_number(i)}/{format_number(total_lines)} baris")
            
            # Tutup file terakhir
            if current_file:
                current_file.close()
        
        print("\n" + "=" * 50)
        print("[ ✓ ] PROSES SELESAI!")
        print("=" * 50)
        
        # Hitung jumlah file yang dibuat
        file_count -= 1
        print(f"\n[ + ] Total file yang dibuat: {file_count}")
        
        # Info file
        for i in range(1, file_count + 1):
            filename = f"{output_name}-{i}.txt"
            if os.path.exists(filename):
                with open(filename, 'r', encoding='utf-8') as f:
                    lines_in_file = sum(1 for _ in f)
                print(f"[ + ] {filename} — {format_number(lines_in_file)} baris")
        
        print(f"\n[ + ] Sisa baris di file terakhir: {format_number(lines_in_file)} baris")
        
    except Exception as e:
        print(f"[ ! ] Error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
