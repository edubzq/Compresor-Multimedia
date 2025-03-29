function compressedFile = jcom_custom(fname, caliQ)
    % jcom_custom: Función que comprime una imagen dada utilizando Huffman personalizado.
    % 
    % Entradas:
    %   fname: nombre del fichero de imagen (por ejemplo 'imagen.bmp').
    %   caliQ: factor de calidad (entero). En este caso, a menor valor de caliQ, mayor calidad (menor cuantización).
    %
    % Salida:
    %   compressedFile: nombre del fichero comprimido (con extensión .huc).

    %--------------------------------------------------------------------------
    % 1. Lectura y preparación de la imagen
    %--------------------------------------------------------------------------
    % imlee: Función que lee la imagen 'fname', la convierte a YCbCr, y la
    % amplía en caso necesario para que sus dimensiones sean múltiplos de 8.
    % Devuelve:
    %  X: imagen original en RGB.
    %  Xamp: imagen ampliada en YCbCr con dimensiones ajustadas a múltiplos de 8.
    %  m, n: dimensiones originales de la imagen.
    %  mamp, namp: dimensiones ampliadas de la imagen (múltiplos de 8).
    [X, Xamp, tipo, m, n, mamp, namp, TO] = imlee(fname);

    %--------------------------------------------------------------------------
    % 2. Cálculo de la DCT bidimensional por bloques de 8x8
    %--------------------------------------------------------------------------
    % imdct: aplica la Transformada Discreta del Coseno (DCT) a la imagen 
    % ampliada Xamp, procesándola por bloques de 8x8.
    Xtrans = imdct(Xamp);

    %--------------------------------------------------------------------------
    % 3. Cuantización de coeficientes
    %--------------------------------------------------------------------------
    % quantmat: cuantiza los coeficientes de la DCT en función del factor de calidad caliQ.
    % Un caliQ bajo implica menor cuantización (más calidad), un caliQ alto mayor cuantización.
    Xlab = quantmat(Xtrans, caliQ);

    %--------------------------------------------------------------------------
    % 4. Reordenación de los coeficientes en zigzag
    %--------------------------------------------------------------------------
    % scan: Recorre cada bloque cuantizado y reordena los coeficientes en zigzag.
    % Devuelve las componentes de luminancia y cromancia (Y, Cb, Cr) reordenadas.
    Xscan = scan(Xlab);

    %--------------------------------------------------------------------------
    % 5. Separación de coeficientes DC y AC
    %--------------------------------------------------------------------------
    % CollectScan: Extrae de cada plano los coeficientes DC (primero de cada bloque)
    % y AC (resto de los coeficientes), generando dos conjuntos: uno para DC y otro para AC.
    [Y_DC_CP, Y_AC_ZCP] = CollectScan(Xscan(:,:,1));
    [Cb_DC_CP, Cb_AC_ZCP] = CollectScan(Xscan(:,:,2));
    [Cr_DC_CP, Cr_AC_ZCP] = CollectScan(Xscan(:,:,3));
    
    %--------------------------------------------------------------------------
    % 6. Cálculo de las frecuencias para Huffman
    %--------------------------------------------------------------------------
    % Freq256: Calcula la distribución de frecuencias de los símbolos en un rango de 0 a 255.
    
    % Calcular frecuencias Huffman para luminancia (Y):
    Freq_Y_DC = Freq256(Y_DC_CP(:, 1)); 
    Freq_Y_AC = Freq256(Y_AC_ZCP(:, 1)); 

    % Calcular frecuencias Huffman para cromancia (Cb y Cr comparten tablas)
    Freq_C_DC = Freq256([Cb_DC_CP(:, 1); Cr_DC_CP(:, 1)]); 
    Freq_C_AC = Freq256([Cb_AC_ZCP(:, 1); Cr_AC_ZCP(:, 1)]); 
    
    %--------------------------------------------------------------------------
    % 7. Construcción de tablas Huffman a medida
    %--------------------------------------------------------------------------
    % HSpecTables: A partir de las frecuencias se generan las tablas BITS y HUFFVAL
    % HCodeTables: Crea las tablas de códigos Huffman a partir de BITS y HUFFVAL
    % HCodingTables: Genera las tablas EHUFCO y EHUFSI para codificación.

    % Tablas Huffman para luminancia (Y)

    % Tabla Y_DC

    [BITS_Y_DC, HUFFVAL_Y_DC] = HSpecTables(Freq_Y_DC);
    [HUFFSIZE_Y_DC, HUFFCODE_Y_DC] = HCodeTables(BITS_Y_DC, HUFFVAL_Y_DC);
    [EHUFCO_Y_DC, EHUFSI_Y_DC] = HCodingTables(HUFFSIZE_Y_DC, HUFFCODE_Y_DC, HUFFVAL_Y_DC);
    ehuf_Y_DC=[EHUFCO_Y_DC EHUFSI_Y_DC];

    % Tabla Y_AC

    [BITS_Y_AC, HUFFVAL_Y_AC] = HSpecTables(Freq_Y_AC);
    [HUFFSIZE_Y_AC, HUFFCODE_Y_AC] = HCodeTables(BITS_Y_AC, HUFFVAL_Y_AC);
    [EHUFCO_Y_AC, EHUFSI_Y_AC] = HCodingTables(HUFFSIZE_Y_AC, HUFFCODE_Y_AC, HUFFVAL_Y_AC);
    ehuf_Y_AC=[EHUFCO_Y_AC EHUFSI_Y_AC];


    % Tablas Huffman para crominancia (Cb y Cr comparten)

    % Tabla C_DC

    [BITS_C_DC, HUFFVAL_C_DC] = HSpecTables(Freq_C_DC);
    [HUFFSIZE_C_DC, HUFFCODE_C_DC] = HCodeTables(BITS_C_DC, HUFFVAL_C_DC);
    [EHUFCO_C_DC, EHUFSI_C_DC] = HCodingTables(HUFFSIZE_C_DC, HUFFCODE_C_DC, HUFFVAL_C_DC);
    ehuf_C_DC=[EHUFCO_C_DC EHUFSI_C_DC];

    % Tabla C_AC

    [BITS_C_AC, HUFFVAL_C_AC] = HSpecTables(Freq_C_AC);
    [HUFFSIZE_C_AC, HUFFCODE_C_AC] = HCodeTables(BITS_C_AC, HUFFVAL_C_AC);
    [EHUFCO_C_AC, EHUFSI_C_AC] = HCodingTables(HUFFSIZE_C_AC, HUFFCODE_C_AC, HUFFVAL_C_AC);
    ehuf_C_AC=[EHUFCO_C_AC EHUFSI_C_AC];


    %--------------------------------------------------------------------------
    % 8. Codificación de los scans con las tablas Huffman personalizadas
    %--------------------------------------------------------------------------
    % EncodeSingleScan: Codifica una componente (Y, Cb o Cr) usando las tablas Huffman
    % generadas (ehuf), tanto para DC como AC.

    CodedY = EncodeSingleScan(Xscan(:,:,1), Y_DC_CP, Y_AC_ZCP, ehuf_Y_DC, ehuf_Y_AC);
    CodedCb = EncodeSingleScan(Xscan(:,:,2), Cb_DC_CP, Cb_AC_ZCP, ehuf_C_DC, ehuf_C_AC);
    CodedCr = EncodeSingleScan(Xscan(:,:,3), Cr_DC_CP, Cr_AC_ZCP, ehuf_C_DC, ehuf_C_AC);

    %--------------------------------------------------------------------------
    % 9. Cálculo de la Relación de Compresión (RC)
    %--------------------------------------------------------------------------
    sizeOriginal = numel(X) * 8;
    sizeCompresion = numel(CodedY) + numel(CodedCb) + numel(CodedCr);
    RC = sizeOriginal / sizeCompresion;

    %--------------------------------------------------------------------------
    % 10. Preparación del nombre y formato del archivo comprimido
    %--------------------------------------------------------------------------
    % Generamos el nombre del archivo comprimido con extensión '.huc'

    [filepath, name, ext] = fileparts(fname);
    compressedFile = fullfile(filepath, [name '.huc']);
    
    %--------------------------------------------------------------------------
    % 11. Conversión de bits a bytes
    %--------------------------------------------------------------------------
    % bits2bytes: Agrupa los bits en bytes y devuelve el número de bits usados 
    % en el último byte de cada secuencia.

    [CodedY, lY] = bits2bytes(CodedY);
    [CodedCb, lCb] = bits2bytes(CodedCb);
    [CodedCr, lCr] = bits2bytes(CodedCr);

    lenCodedY = uint32(length(CodedY));
    lenCodedCb = uint32(length(CodedCb));
    lenCodedCr = uint32(length(CodedCr));

    % Longitudes de las tablas Huffman (número de índices en BITS)
    len_Y_DC = uint8(length(BITS_Y_DC));
    len_Y_AC = uint8(length(BITS_Y_AC));
    len_C_DC = uint8(length(BITS_C_DC));
    len_C_AC = uint8(length(BITS_C_AC));
    

    %--------------------------------------------------------------------------
    % 12. Escritura del archivo comprimido
    %--------------------------------------------------------------------------
    % La estructura del archivo incluye:
    % - Dimensiones originales (m, n)
    % - Dimensiones ampliadas (mamp, namp)
    % - Longitudes de los datos codificados Y, Cb, Cr
    % - Bits sobrantes en el último byte de cada canal (lY, lCb, lCr)
    % - Datos codificados Y, Cb, Cr
    % - Factor de calidad caliQ
    % - Longitudes y tablas Huffman personalizadas (BITS e HUFFVAL) para Y (DC,AC) y C (DC,AC)

    tam = [mamp namp];
    fid = fopen(compressedFile, 'w');
    % Dimensiones
    fwrite(fid, m, 'uint16'); 
    fwrite(fid, n, 'uint16'); 
    fwrite(fid, mamp, 'uint16');
    fwrite(fid, namp, 'uint16');
    % Longitudes de las secuencias codificadas
    fwrite(fid, lenCodedY, 'uint32');
    fwrite(fid, lenCodedCb, 'uint32');
    fwrite(fid, lenCodedCr, 'uint32');
    % Bits del último byte en cada canal
    fwrite(fid, lY, 'uint8');
    fwrite(fid, lCb, 'uint8');
    fwrite(fid, lCr, 'uint8');
    % Datos codificados
    fwrite(fid, CodedY, 'uint8');
    fwrite(fid, CodedCb, 'uint8');
    fwrite(fid, CodedCr, 'uint8');
    % Factor de calidad
    fwrite(fid, caliQ, 'uint16');
    % Longitudes de las tablas BITS
    fwrite(fid, len_Y_DC, 'uint8');
    fwrite(fid, len_Y_AC, 'uint8');
    fwrite(fid, len_C_DC, 'uint8');
    fwrite(fid, len_C_AC, 'uint8');
    % Tablas BITS
    fwrite(fid, BITS_Y_DC, 'uint8');
    fwrite(fid, BITS_Y_AC, 'uint8');
    fwrite(fid, BITS_C_DC, 'uint8');
    fwrite(fid, BITS_C_AC, 'uint8');
    % Tablas HUFFVAL
    fwrite(fid, HUFFVAL_Y_DC, 'uint8');
    fwrite(fid, HUFFVAL_Y_AC, 'uint8');
    fwrite(fid, HUFFVAL_C_DC, 'uint8');
    fwrite(fid, HUFFVAL_C_AC, 'uint8');
    fclose(fid);
    
    %fprintf('Relación de compresión (RC): %.2f\n', RC);
end