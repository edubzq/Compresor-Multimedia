function [MSE, RC] = jdes_dflt(fname)
    % jdes_dflt: Función de descompresión correspondiente a jcom_dflt
    % que usa tablas Huffman por defecto.
    %
    % Entradas:
    %   fname: nombre del fichero de imagen original (por ejemplo 'imagen.bmp').
    %           La función asume que el archivo comprimido tiene la misma 
    %           raíz de nombre con extensión .hud (por ejemplo 'imagen.hud').
    %
    % Salidas:
    %   MSE: Error Cuadrático Medio entre la imagen original y la descomprimida.
    %   RC: Relación de compresión obtenida (tamaño original / tamaño comprimido).

    %--------------------------------------------------------------------------
    % 1. Lectura del archivo comprimido (.hud)
    %--------------------------------------------------------------------------
    compressedFile = [fname(1:end-4) '.hud'];

    % Abrimos el archivo para lectura
    fid = fopen(compressedFile, 'r');

    m = double(fread(fid, 1, 'uint16')); % Altura original de la imagen
    n = double(fread(fid, 1, 'uint16'));   % Anchura original de la imagen   
    mamp = double(fread(fid,1, 'uint16')); % Altura ampliada
    namp = double(fread(fid,1, 'uint16')); % Anchura ampliada

    lenCodedY = double(fread(fid, 1,'uint32')); % Longitud del flujo Y codificado
    lenCodedCb = double(fread(fid, 1,'uint32')); % Longitud del flujo Cb codificado
    lenCodedCr = double(fread(fid, 1,'uint32')); % Longitud del flujo Cr codificado

    lY = double(fread(fid, 1,'uint8')); % Bits usados en el último byte de Y
    lCb = double(fread(fid,1, 'uint8')); % Bits usados en el último byte de Cb
    lCr = double(fread(fid,1, 'uint8')); % Bits usados en el último byte de Cr

    % Leemos los datos codificados en bytes
    CodedY = double(fread(fid,lenCodedY, 'uint8'));
    CodedCb = double(fread(fid,lenCodedCb, 'uint8'));
    CodedCr = double(fread(fid,lenCodedCr, 'uint8'));

     % Factor de calidad usado durante la compresión
    caliQ = double(fread(fid, 1, 'uint16'));

    fclose(fid);

    %--------------------------------------------------------------------------
    % 2. Conversión de bytes a bits
    %--------------------------------------------------------------------------
    % Reconstruimos las secuencias binarias a partir de los bytes leídos.

    CodedY= bytes2bits(CodedY, lY);
    CodedCb= bytes2bits(CodedCb, lCb);
    CodedCr= bytes2bits(CodedCr, lCr);

    %--------------------------------------------------------------------------
    % 3. Decodificación de los Scans con Huffman por defecto
    %--------------------------------------------------------------------------
    % tam: vector con las dimensiones ampliadas
    % DecodeScans_dflt: Decodifica las secuencias CodedY, CodedCb, CodedCr 
    % usando las tablas Huffman por defecto, reconstruyendo el "scan" original.
    tam = [mamp namp];
    XScanrec=DecodeScans_dflt(CodedY,CodedCb,CodedCr,tam);

    %--------------------------------------------------------------------------
    % 4. Reconstruir el orden natural desde zigzag
    %--------------------------------------------------------------------------
    % invscan: Invierte la operación de "scan" y restaura los coeficientes 
    % en el orden de los bloques 8x8.
    Xlabrec=invscan(XScanrec);

    %--------------------------------------------------------------------------
    % 5. Descuantización
    %--------------------------------------------------------------------------
    % desquantmat: Aplica la operación inversa de cuantización, usando el mismo caliQ.
    % Esto nos da de vuelta los coeficientes DCT reconstruidos.
    Xtransrec=desquantmat(Xlabrec, caliQ);

    %--------------------------------------------------------------------------
    % 6. iDCT por bloques
    %--------------------------------------------------------------------------
    % imidct: Aplica la DCT inversa a los bloques 8x8, reconstruyendo la imagen
    % YCbCr ampliada.
    Xamprec = imidct(Xtransrec,m, n);

    %--------------------------------------------------------------------------
    % 7. Conversión desde YCbCr a RGB
    %--------------------------------------------------------------------------
    % La función ycbcr2rgb asume valores en [0,1], así que se normaliza con /255.
    % Luego se redondea y se multiplica por 255 para volver al rango [0,255].
    Xrecrd=round(ycbcr2rgb(Xamprec/255)*255);
    Xrec=uint8(Xrecrd);

    %--------------------------------------------------------------------------
    % 8. Ajuste al tamaño original
    %--------------------------------------------------------------------------
    Xrec=Xrec(1:m,1:n, 1:3);

    %--------------------------------------------------------------------------
    % 9. Cálculo de MSE y RC
    %--------------------------------------------------------------------------
    originalFile = [fname(1:end-4) '.bmp'];
    [X, Xamp, tipo, m, n, mamp, namp, TO]=imlee(originalFile);
    % Calcular MSE y RC
    sizeOriginal = numel(X) * 8; %(tamaño en bits)
    sizeCompresion = numel(CodedY) + numel(CodedCb) + numel(CodedCr);
    RC = sizeOriginal/sizeCompresion;

    % MSE: Error cuadrático medio entre original y reconstruida
    MSE = sum((double(X(:)) - double(Xrec(:))).^2) / numel(X);

    %--------------------------------------------------------------------------
    % 10. Guardar la imagen descomprimida para visualizar cambios
    %--------------------------------------------------------------------------
    % Guardamos la imagen descomprimida con el factor de calidad en el nombre
    
    imwrite(Xrec, [fname(1:end-4) '_' num2str(caliQ) '_des_dflt.bmp']);

    % Visualizar imágenes
    %figure, imshow(X), title('Imagen Original');
    %figure, imshow(Xrec), title('Imagen Descomprimida');
    %fprintf('Error cuadrático medio (MSE): %.2f\n', MSE);
    %fprintf('Relación de compresión (RC): %.2f\n', RC);
end
