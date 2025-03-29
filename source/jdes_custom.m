function [MSE, RC] = jdes_custom(fname)
    % jdes_custom: Función de descompresión correspondiente a jcom_custom.
    % Esta función utiliza las tablas Huffman personalizadas guardadas en el
    % archivo comprimido .huc.
    % Entradas:
    %   fname: nombre del fichero de imagen original (por ejemplo 'imagen.bmp').
    %           Se asume que el archivo comprimido tiene extensión .huc 
    %           (ejemplo: 'imagen.huc').
    %
    % Salidas:
    %   MSE: Error Cuadrático Medio entre la imagen original y la imagen descomprimida.
    %   RC: Relación de Compresión (tamaño original / tamaño comprimido).

    %--------------------------------------------------------------------------
    % 1. Lectura del archivo comprimido (.huc)
    %--------------------------------------------------------------------------
    compressedFile = [fname(1:end-4) '.huc'];
    fid = fopen(compressedFile, 'r');

    % Lee dimensiones originales y ampliadas
    m = double(fread(fid, 1, 'uint16'));
    n = double(fread(fid, 1, 'uint16'));      
    mamp = double(fread(fid,1, 'uint16'));
    namp = double(fread(fid,1, 'uint16'));

    % Lee longitudes de las secuencias codificadas (Y, Cb, Cr)
    lenCodedY = double(fread(fid, 1,'uint32'));
    lenCodedCb = double(fread(fid, 1,'uint32'));
    lenCodedCr = double(fread(fid, 1,'uint32'));

    % Bits usados en el último byte para cada canal
    lY = double(fread(fid, 1,'uint8'));
    lCb = double(fread(fid,1, 'uint8'));
    lCr = double(fread(fid,1, 'uint8'));

    % Datos codificados para Y, Cb y Cr
    CodedY = double(fread(fid,lenCodedY, 'uint8'));
    CodedCb = double(fread(fid,lenCodedCb, 'uint8'));
    CodedCr = double(fread(fid,lenCodedCr, 'uint8'));

    % Lee el factor de calidad utilizado en la compresión
    caliQ = double(fread(fid, 1, 'uint16'));

    % Lee las longitudes de las tablas BITS para Y_DC, Y_AC, C_DC, C_AC
    len_Y_DC = fread(fid, 1, 'uint8');
    len_Y_AC = fread(fid, 1, 'uint8');
    len_C_DC = fread(fid, 1, 'uint8');
    len_C_AC = fread(fid, 1, 'uint8');

    % Lee los vectores BITS
    BITS_Y_DC = fread(fid, len_Y_DC, 'uint8');
    BITS_Y_AC = fread(fid, len_Y_AC, 'uint8');
    BITS_C_DC = fread(fid, len_C_DC, 'uint8');
    BITS_C_AC = fread(fid, len_C_AC, 'uint8');

    % Lee los vectores HUFFVAL
    HUFFVAL_Y_DC = fread(fid, sum(BITS_Y_DC), 'uint8');
    HUFFVAL_Y_AC = fread(fid, sum(BITS_Y_AC), 'uint8');
    HUFFVAL_C_DC = fread(fid, sum(BITS_C_DC), 'uint8');
    HUFFVAL_C_AC = fread(fid, sum(BITS_C_AC), 'uint8');
    
    fclose(fid);
    
    %--------------------------------------------------------------------------
    % 2. Conversión de bytes a bits
    %--------------------------------------------------------------------------
    % Reconstruye las secuencias binarias de cada canal a partir de los bytes.
    CodedY= bytes2bits(CodedY, lY);
    CodedCb= bytes2bits(CodedCb, lCb);
    CodedCr= bytes2bits(CodedCr, lCr);
    
    %--------------------------------------------------------------------------
    % 3. Reconstrucción de tablas Huffman a partir de BITS y HUFFVAL
    %--------------------------------------------------------------------------

    % Luminancia (Y)

    [HUFFSIZE_Y_DC, HUFFCODE_Y_DC] = HCodeTables(BITS_Y_DC, HUFFVAL_Y_DC);
    [MINCODE_Y_DC, MAXCODE_Y_DC, VALPTR_Y_DC] = HDecodingTables(BITS_Y_DC, HUFFCODE_Y_DC);
    
    [HUFFSIZE_Y_AC, HUFFCODE_Y_AC] = HCodeTables(BITS_Y_AC, HUFFVAL_Y_AC);
    [MINCODE_Y_AC, MAXCODE_Y_AC, VALPTR_Y_AC] = HDecodingTables(BITS_Y_AC, HUFFCODE_Y_AC);

    % Crominancia (C - compartido por Cb y Cr)
   
    [HUFFSIZE_C_DC, HUFFCODE_C_DC] = HCodeTables(BITS_C_DC, HUFFVAL_C_DC);
    [MINCODE_C_DC, MAXCODE_C_DC, VALPTR_C_DC] = HDecodingTables(BITS_C_DC, HUFFCODE_C_DC);
    
    [HUFFSIZE_C_AC, HUFFCODE_C_AC] = HCodeTables(BITS_C_AC, HUFFVAL_C_AC);
    [MINCODE_C_AC, MAXCODE_C_AC, VALPTR_C_AC] = HDecodingTables(BITS_C_AC, HUFFCODE_C_AC);
    
    
    
    %--------------------------------------------------------------------------
    % 4. Decodificación de los scans
    %--------------------------------------------------------------------------
    % DecodeSingleScan: Decodifica las secuencias de bits usando las tablas Huffman
    % proporcionadas. Necesita las tablas para DC y AC de cada plano (Y, Cb, Cr).

    tam = [mamp, namp];

    % Decodificar para Y
    YScanrec = DecodeSingleScan(CodedY, MINCODE_Y_DC, MAXCODE_Y_DC, VALPTR_Y_DC, HUFFVAL_Y_DC,MINCODE_Y_AC, MAXCODE_Y_AC, VALPTR_Y_AC, HUFFVAL_Y_AC, tam);
    % Decodificar para Cb
    CbScanrec = DecodeSingleScan(CodedCb, MINCODE_C_DC, MAXCODE_C_DC, VALPTR_C_DC, HUFFVAL_C_DC,MINCODE_C_AC, MAXCODE_C_AC, VALPTR_C_AC, HUFFVAL_C_AC, tam);
    % Decodificar para Cr
    CrScanrec = DecodeSingleScan(CodedCr, MINCODE_C_DC, MAXCODE_C_DC, VALPTR_C_DC, HUFFVAL_C_DC,MINCODE_C_AC, MAXCODE_C_AC, VALPTR_C_AC, HUFFVAL_C_AC, tam);

    %--------------------------------------------------------------------------
    % 5. Reconstruir la imagen desde el scan
    %--------------------------------------------------------------------------
    % Combinar los tres planos (Y, Cb, Cr)
    XScanrec = cat(3, YScanrec, CbScanrec, CrScanrec);

    %--------------------------------------------------------------------------
    % 4. Reconstruir el orden natural desde zigzag
    %--------------------------------------------------------------------------
    % invscan: Invierte la operación de "scan" y restaura los coeficientes 
    % en el orden de los bloques 8x8.
    Xlabrec = invscan(XScanrec);

    %--------------------------------------------------------------------------
    % 5. Descuantización
    %--------------------------------------------------------------------------
    % desquantmat: Aplica la operación inversa de cuantización, usando el mismo caliQ.
    % Esto nos da de vuelta los coeficientes DCT reconstruidos.
    Xtransrec = desquantmat(Xlabrec, caliQ);

    %--------------------------------------------------------------------------
    % 6. iDCT por bloques
    %--------------------------------------------------------------------------
    % imidct: Aplica la DCT inversa a los bloques 8x8, reconstruyendo la imagen
    % YCbCr ampliada.
    Xamprec = imidct(Xtransrec, m, n);

    %--------------------------------------------------------------------------
    % 7. Conversión desde YCbCr a RGB
    %--------------------------------------------------------------------------
    % La función ycbcr2rgb asume valores en [0,1], así que se normaliza con /255.
    % Luego se redondea y se multiplica por 255 para volver al rango [0,255].
    Xrec = uint8(round(ycbcr2rgb(Xamprec / 255) * 255));

    %--------------------------------------------------------------------------
    % 8. Ajuste al tamaño original
    %--------------------------------------------------------------------------
    Xrec = Xrec(1:m, 1:n, :);

    %--------------------------------------------------------------------------
    % 9. Cálculo de MSE y RC
    %--------------------------------------------------------------------------
    originalFile = [fname(1:end-4) '.bmp'];
    [X, ~, ~, ~, ~, ~, ~, ~] = imlee(originalFile);
    sizeOriginal = numel(X) * 8;
    sizeCompresion = numel(CodedY) + numel(CodedCb) + numel(CodedCr);
    RC = sizeOriginal / sizeCompresion;
    MSE = sum((double(X(:)) - double(Xrec(:))).^2) / numel(X);

    %--------------------------------------------------------------------------
    % 10. Guardar la imagen descomprimida para visualización
    %--------------------------------------------------------------------------
    imwrite(Xrec, [fname(1:end-4) '_' num2str(caliQ) '_des_custom.bmp']);

    % Visualiza las imágenes
    %figure, imshow(X), title('Imagen Original');
    %figure, imshow(Xrec), title('Imagen Descomprimida');
    
end