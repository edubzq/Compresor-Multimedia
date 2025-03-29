% Lista de imágenes a analizar
imageList = {'Img02.bmp', 'Img04.bmp', 'Img08.bmp', 'Img11.bmp', 'Img13.bmp', 'Img15.bmp'};

% Conjunto de valores del factor de calidad a utilizar.
% A menor valor de FQ, mayor calidad (menor cuantización), 
% a mayor valor de FQ, menor calidad (mayor cuantización).
FQ = [1, 50, 100, 150, 200, 500];

numImages = numel(imageList); % Número de imágenes a procesar
numFQ = numel(FQ);            % Número de factores de calidad

% Inicialización de matrices para almacenar los resultados:
% MSE y RC tanto para el método por defecto como para el método a medida.
MSE_default = zeros(numImages, numFQ);
MSE_custom = zeros(numImages, numFQ);
RC_default = zeros(numImages, numFQ);
RC_custom = zeros(numImages, numFQ);

%--------------------------------------------------------------------------
% Bucle principal sobre cada imagen
%--------------------------------------------------------------------------
for i = 1:numImages
    fname = imageList{i}; % Nombre de la imagen actual
    
    %----------------------------------------------------------------------
    % Bucle sobre cada factor de calidad
    %----------------------------------------------------------------------
    for q = 1:numFQ
        fqVal = FQ(q); % Factor de calidad actual
        
        %---------------------------
        % Compresión y descompresión con Huffman por defecto
        %---------------------------
        % jcom_dflt: comprime la imagen 'fname' con factor de calidad 'fqVal'.
        % Devuelve el nombre del archivo comprimido.
        cfname = jcom_dflt(fname, fqVal);
        
        % jdes_dflt: descomprime el archivo comprimido por jcom_dflt.
        % Devuelve MSE y RC para la imagen resultante.
        [MSEd, RCd] = jdes_dflt(cfname);
        
        % Almacena los resultados en las matrices correspondientes.
        MSE_default(i,q) = MSEd;
        RC_default(i,q) = RCd;
        
        %---------------------------
        % Compresión y descompresión con Huffman a medida (personalizado)
        %---------------------------
        % jcom_custom: comprime la imagen 'fname' con tablas Huffman generadas
        % a medida en función de los datos de la propia imagen.
        cfname1 = jcom_custom(fname, fqVal);
        
        % jdes_custom: descomprime el archivo comprimido por jcom_custom.
        % Devuelve MSE y RC para la imagen resultante usando tablas Huffman personalizadas.
        [MSEc, RCc] = jdes_custom(cfname1);
        
        % Almacena los resultados en las matrices correspondientes.
        MSE_custom(i,q) = MSEc;
        RC_custom(i,q) = RCc;      
    end
    
    %----------------------------------------------------------------------
    % Crear la tabla de resultados para la imagen i
    %----------------------------------------------------------------------
    % Se preparan los datos en vectores columna para crear la tabla.
    FQ_values = FQ(:);           % Vector columna con factores de calidad
    MSE_d = MSE_default(i,:)';   % MSE  por defecto para la imagen i
    MSE_c = MSE_custom(i,:)';    % MSE  a medida para la imagen i
    RC_d = RC_default(i,:)';     % RC por defecto para la imagen i
    RC_c = RC_custom(i,:)';      % RC a medida para la imagen i
    
    % Se crea una tabla con los resultados y se les ponen nombres a las columnas.
    T = table(FQ_values, MSE_d, RC_d, MSE_c, RC_c, ...
        'VariableNames', {'FQ','MSE_default','RC_default(%)','MSE_custom','RC_custom(%)'});
    
    % Se guarda la tabla en un archivo CSV para cada imagen
    outputf = ['resultados_' imageList{i} '.csv'];
    writetable(T, outputf);
    
    %----------------------------------------------------------------------
    % Crear la gráfica comparativa MSE vs RC para la imagen i
    %----------------------------------------------------------------------
    fig = figure('Visible', 'off'); % Crea una figura sin mostrar en pantalla
    
    % Graficar MSE vs RC para Huffman por defecto
    % Se usa semilogy para representar MSE en escala logarítmica en el eje Y.
    semilogy(RC_default(i,:), MSE_default(i,:), '-o', 'LineWidth', 2, 'MarkerSize', 8);
    hold on;
    
    % Graficar MSE vs RC para Huffman a medida
    semilogy(RC_custom(i,:), MSE_custom(i,:), '-o', 'LineWidth', 2, 'MarkerSize', 8);
    hold off;
    
    % Etiquetado de ejes y título
    xlabel('Relacion de Compresión (RC)[%]');
    ylabel('MSE');
    title(['Comparación MSE vs RC - ' imageList{i}], 'FontSize', 14);
    
    % Leyenda para distinguir los dos métodos (por defecto y a medida)
    legend('Huffman por defecto', 'Huffman a medida', 'Location', 'best');
    grid on;
    
    % Guardar la figura como imagen PNG con 300 dpi de resolución.
    [~, name, ~] = fileparts(imageList{i});
    outputf = [name '_comparacion_MSE_RC.png'];
    print(fig, outputf, '-dpng', '-r300');
    
    % Cierra la figura para liberar memoria
    close(fig);
    
end
