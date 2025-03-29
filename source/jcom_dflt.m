function compressedFile = jcom_dflt(fname, caliQ)
    % jcom_dflt: Función que comprime una imagen dada utilizando Huffman por defecto.
    % 
    % Entradas:
    %   fname: nombre del fichero de imagen (por ejemplo 'imagen.bmp').
    %   caliQ: factor de calidad (entero). En este caso, a menor valor de caliQ, mayor calidad (menor cuantización).
    %
    % Salida:
    %   compressedFile: nombre del fichero comprimido (con extensión .hud).

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
    % 5. Codificación Huffman por defecto
    %--------------------------------------------------------------------------
    % EncodeScans_dflt: Codifica las tres componentes (Y, Cb, Cr)
    % utilizando códigos Huffman por defecto.
    [CodedY, CodedCb, CodedCr] = EncodeScans_dflt(Xscan);

    %--------------------------------------------------------------------------
    % 6. Cálculo de la Relación de Compresión (RC)
    %--------------------------------------------------------------------------
    % Tamaño original en bits:
    sizeOriginal = numel(X) * 8; 
    % Tamaño comprimido en bits:
    sizeCompresion = numel(CodedY) + numel(CodedCb) + numel(CodedCr);
    % Relación de compresión: tamaño original / tamaño comprimido
    RC = sizeOriginal / sizeCompresion;

    %--------------------------------------------------------------------------
    % 7. Generación del nombre del archivo comprimido
    %--------------------------------------------------------------------------
    % Cambia la extensión del archivo original a '.hud'
    [filepath, name, ext] = fileparts(fname);
    compressedFile = fullfile(filepath, [name '.hud']);

    %--------------------------------------------------------------------------
    % 8. Conversión de secuencias de bits a secuencias de bytes
    %--------------------------------------------------------------------------
    % bits2bytes: Esta función agrupa los bits en bytes y también devuelve
    % la información necesaria (lY, lCb, lCr) que indica la cantidad de 
    % bits sobrantes en el último byte.
    [CodedY, lY] = bits2bytes(CodedY);
    [CodedCb, lCb] = bits2bytes(CodedCb);
    [CodedCr, lCr] = bits2bytes(CodedCr);

    % Prepara tamaños para escritura
    lenCodedY = uint32(length(CodedY));
    lenCodedCb = uint32(length(CodedCb));
    lenCodedCr = uint32(length(CodedCr));

    %--------------------------------------------------------------------------
    % 9. Escritura del archivo comprimido
    %--------------------------------------------------------------------------
    % Estructura del archivo comprimido:
    %   - m, n: dimensiones originales
    %   - mamp, namp: dimensiones ampliadas (múltiplos de 8)
    %   - lenCodedY, lenCodedCb, lenCodedCr: longitudes de los vectores codificados
    %   - lY, lCb, lCr: bits usados en el último byte de cada canal
    %   - CodedY, CodedCb, CodedCr: datos comprimidos para cada componente
    %   - caliQ: factor de calidad
    fid = fopen(compressedFile, 'w');
    fwrite(fid, m, 'uint16'); 
    fwrite(fid, n, 'uint16'); 
    fwrite(fid, mamp, 'uint16');
    fwrite(fid, namp, 'uint16');
    fwrite(fid, lenCodedY, 'uint32');
    fwrite(fid, lenCodedCb, 'uint32');
    fwrite(fid, lenCodedCr, 'uint32');
    fwrite(fid, lY, 'uint8');
    fwrite(fid, lCb, 'uint8');
    fwrite(fid, lCr, 'uint8');
    fwrite(fid, CodedY, 'uint8');
    fwrite(fid, CodedCb, 'uint8');
    fwrite(fid, CodedCr, 'uint8');
    fwrite(fid, caliQ, 'uint16');
    fclose(fid);

    %--------------------------------------------------------------------------
    % 10. Muestra la Relación de Compresión
    %--------------------------------------------------------------------------
    fprintf('Relación de compresión (RC): %.2f\n', RC);

    % La función devuelve el nombre del archivo comprimido
end