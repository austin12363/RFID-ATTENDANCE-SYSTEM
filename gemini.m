function ECE_Project_GUI
    % Main entry point for the Signals & Systems Project GUI
    % Requirements covered:
    % 1. Signal Transformation (Shift, Dilation, Scaling) [cite: 17, 18]
    % 2. Signal Manipulation (Add, Sub, Mult) [cite: 19, 20]
    % 3. LTI System Check [cite: 21]
    % 4. Discrete Convolution [cite: 22]

    % --- 1. SETUP MAIN FIGURE ---
    f = figure('Name', 'ECE04L Signals Project', ...
               'NumberTitle', 'off', ...
               'Position', [100, 100, 1000, 600], ...
               'Color', [0.94 0.94 0.94]);

    % --- 2. CONTROL PANEL (Left Side) ---
    pnlControls = uipanel('Parent', f, 'Title', 'Control Panel', ...
                          'Position', [0.02, 0.02, 0.3, 0.96], ...
                          'FontSize', 12);

    % Select Operation Mode
    uicontrol('Parent', pnlControls, 'Style', 'text', 'String', 'Select Operation:', ...
              'Position', [10, 520, 200, 20], 'HorizontalAlignment', 'left');
    
    hOpMode = uicontrol('Parent', pnlControls, 'Style', 'popupmenu', ...
                        'String', {'1. Signal Transformation', '2. Signal Manipulation', '3. LTI System Check', '4. Discrete Convolution'}, ...
                        'Position', [10, 490, 260, 30], ...
                        'Callback', @updateVisibility);

    % --- INPUT FIELDS (Visibility toggled based on mode) ---
    
    % Input Signal 1 (Used for everything)
    lblSig1 = uicontrol('Parent', pnlControls, 'Style', 'text', 'String', 'Signal x[n] (vector):', ...
              'Position', [10, 440, 260, 20], 'HorizontalAlignment', 'left');
    txtSig1 = uicontrol('Parent', pnlControls, 'Style', 'edit', 'String', '[1 2 3 4 5]', ...
              'Position', [10, 420, 260, 25]);

    % Input Signal 2 (Used for Manipulation & Convolution)
    lblSig2 = uicontrol('Parent', pnlControls, 'Style', 'text', 'String', 'Signal 2 / h[n] (vector):', ...
              'Position', [10, 380, 260, 20], 'HorizontalAlignment', 'left');
    txtSig2 = uicontrol('Parent', pnlControls, 'Style', 'edit', 'String', '[1 1 1]', ...
              'Position', [10, 360, 260, 25]);

    % Time Vector (Used for plotting)
    lblTime = uicontrol('Parent', pnlControls, 'Style', 'text', 'String', 'Time Vector n:', ...
              'Position', [10, 320, 260, 20], 'HorizontalAlignment', 'left');
    txtTime = uicontrol('Parent', pnlControls, 'Style', 'edit', 'String', '0:4', ...
              'Position', [10, 300, 260, 25]);

    % --- PARAMETERS (Transformation Specific) ---
    pnlTrans = uipanel('Parent', pnlControls, 'Title', 'Transformation Params', ...
                       'Position', [0.05, 0.3, 0.9, 0.18]);
    
    uicontrol('Parent', pnlTrans, 'Style', 'text', 'String', 'Shift (k):', 'Position', [5, 60, 60, 20]);
    txtShift = uicontrol('Parent', pnlTrans, 'Style', 'edit', 'String', '2', 'Position', [70, 60, 40, 25]);

    uicontrol('Parent', pnlTrans, 'Style', 'text', 'String', 'Scale (a):', 'Position', [5, 35, 60, 20]);
    txtScale = uicontrol('Parent', pnlTrans, 'Style', 'edit', 'String', '2', 'Position', [70, 35, 40, 25]);
    
    uicontrol('Parent', pnlTrans, 'Style', 'text', 'String', 'Amp (A):', 'Position', [120, 60, 50, 20]);
    txtAmp = uicontrol('Parent', pnlTrans, 'Style', 'edit', 'String', '1', 'Position', [170, 60, 40, 25]);
    
    % --- LTI SELECTION (LTI Specific) ---
    lblLTI = uicontrol('Parent', pnlControls, 'Style', 'text', 'String', 'Select System to Test:', ...
              'Position', [10, 240, 260, 20], 'HorizontalAlignment', 'left', 'Visible', 'off');
    hLTIMenu = uicontrol('Parent', pnlControls, 'Style', 'popupmenu', ...
                        'String', {'y[n] = 2*x[n] (Linear, TI)', 'y[n] = x[n]^2 (Non-Lin, TI)', 'y[n] = n*x[n] (Linear, TV)', 'y[n] = x[n] + 1 (Non-Lin, TI)'}, ...
                        'Position', [10, 210, 260, 30], 'Visible', 'off');

    % --- MANIPULATION SELECTOR ---
    lblManip = uicontrol('Parent', pnlControls, 'Style', 'text', 'String', 'Math Operation:', ...
              'Position', [10, 240, 260, 20], 'HorizontalAlignment', 'left', 'Visible', 'off');
    hManipMenu = uicontrol('Parent', pnlControls, 'Style', 'popupmenu', ...
                        'String', {'Addition (x1 + x2)', 'Subtraction (x1 - x2)', 'Multiplication (x1 .* x2)'}, ...
                        'Position', [10, 210, 260, 30], 'Visible', 'off');

    % CALCULATE BUTTON
    btnCalc = uicontrol('Parent', pnlControls, 'Style', 'pushbutton', 'String', 'CALCULATE / PLOT', ...
                        'Position', [10, 100, 260, 50], ...
                        'BackgroundColor', [0.2, 0.6, 1.0], 'ForegroundColor', 'white', ...
                        'FontWeight', 'bold', 'FontSize', 12, ...
                        'Callback', @runCalculations);

    % RESULT TEXT BOX (For LTI results)
    lblRes = uicontrol('Parent', pnlControls, 'Style', 'text', 'String', 'Status / Result:', ...
              'Position', [10, 60, 260, 20], 'HorizontalAlignment', 'left');
    txtResult = uicontrol('Parent', pnlControls, 'Style', 'edit', 'String', 'Ready...', ...
              'Position', [10, 10, 260, 50], 'Max', 2, 'HorizontalAlignment', 'left', 'Enable', 'inactive');

    % --- 3. PLOTTING AREA (Right Side) ---
    pnlPlot = uipanel('Parent', f, 'Title', 'Plotting Area', ...
                      'Position', [0.34, 0.02, 0.64, 0.96]);

    % --- CALLBACK FUNCTIONS ---

    function updateVisibility(~, ~)
        % Updates which inputs are shown based on the selected mode
        mode = hOpMode.Value;
        
        % Default: Hide specific controls
        set(pnlTrans, 'Visible', 'off');
        set(hLTIMenu, 'Visible', 'off');
        set(lblLTI, 'Visible', 'off');
        set(hManipMenu, 'Visible', 'off');
        set(lblManip, 'Visible', 'off');
        set(lblSig2, 'Enable', 'off'); set(txtSig2, 'Enable', 'off');
        
        switch mode
            case 1 % Transformation [cite: 17, 18]
                set(pnlTrans, 'Visible', 'on');
            case 2 % Manipulation [cite: 19]
                set(hManipMenu, 'Visible', 'on');
                set(lblManip, 'Visible', 'on');
                set(lblSig2, 'Enable', 'on'); set(txtSig2, 'Enable', 'on');
            case 3 % LTI Check [cite: 21]
                set(hLTIMenu, 'Visible', 'on');
                set(lblLTI, 'Visible', 'on');
            case 4 % Convolution [cite: 22]
                set(lblSig2, 'Enable', 'on'); set(txtSig2, 'Enable', 'on');
                set(lblSig2, 'String', 'Impulse Response h[n]:');
        end
    end

    function runCalculations(~, ~)
        % Main Logic Block
        try
            mode = hOpMode.Value;
            
            % Get common inputs
            x = str2num(txtSig1.String); %#ok<ST2NM>
            n = str2num(txtTime.String); %#ok<ST2NM>
            
            % Clear plotting panel area
            delete(get(pnlPlot, 'Children'));
            
            switch mode
                % ---------------------------------------------------------
                % CASE 1: SIGNAL TRANSFORMATION [cite: 17, 18]
                % ---------------------------------------------------------
                case 1 
                    k = str2double(txtShift.String);
                    a = str2double(txtScale.String);
                    A = str2double(txtAmp.String);
                    
                    % Operations
                    n_shifted = n - k;   % Time Shifting
                    n_scaled  = n_shifted ./ a; % Time Dilation/Compression
                    y_final   = x .* A;  % Amplitude Scaling
                    
                    % Plotting
                    ax1 = subplot(2,1,1, 'Parent', pnlPlot);
                    stem(ax1, n, x, 'filled', 'LineWidth', 2);
                    title(ax1, 'Original Signal x[n]'); grid(ax1, 'on');
                    
                    ax2 = subplot(2,1,2, 'Parent', pnlPlot);
                    stem(ax2, n_scaled, y_final, 'r', 'filled', 'LineWidth', 2);
                    title(ax2, sprintf('Transformed: Shift=%d, Scale=%.1f, Amp=%.1f', k, a, A)); 
                    grid(ax2, 'on');
                    
                    set(txtResult, 'String', 'Transformation Complete.');

                % ---------------------------------------------------------
                % CASE 2: SIGNAL MANIPULATION [cite: 19, 20]
                % ---------------------------------------------------------
                case 2 
                    x2 = str2num(txtSig2.String); %#ok<ST2NM>
                    
                    % Error Check: Lengths must match
                    if length(x) ~= length(x2)
                        errordlg('Signals must be the same length for manipulation.', 'Dimension Error');
                        return;
                    end
                    
                    op = hManipMenu.Value;
                    opStr = '';
                    if op == 1
                        y = x + x2; opStr = 'Addition';
                    elseif op == 2
                        y = x - x2; opStr = 'Subtraction';
                    else
                        y = x .* x2; opStr = 'Multiplication';
                    end
                    
                    % Plotting
                    ax1 = subplot(3,1,1, 'Parent', pnlPlot);
                    stem(ax1, n, x, 'filled'); title(ax1, 'Signal 1'); grid(ax1, 'on');
                    
                    ax2 = subplot(3,1,2, 'Parent', pnlPlot);
                    stem(ax2, n, x2, 'filled'); title(ax2, 'Signal 2'); grid(ax2, 'on');
                    
                    ax3 = subplot(3,1,3, 'Parent', pnlPlot);
                    stem(ax3, n, y, 'g', 'filled', 'LineWidth', 2); 
                    title(ax3, ['Result: ' opStr]); grid(ax3, 'on');
                    
                    set(txtResult, 'String', ['Computed ' opStr]);

                % ---------------------------------------------------------
                % CASE 3: LTI SYSTEM CHECK [cite: 21]
                % ---------------------------------------------------------
                case 3 
                    % Pre-determined logic for the dropdown items
                    sysIdx = hLTIMenu.Value;
                    resultStr = '';
                    
                    ax1 = subplot(1,1,1, 'Parent', pnlPlot);
                    stem(ax1, n, x, 'filled'); title(ax1, 'Input Signal x[n]');
                    
                    if sysIdx == 1 % y = 2x
                        resultStr = sprintf('System: y[n] = 2x[n]\n\nLinearity: LINEAR\n(Satisfies superposition)\n\nTime Invariance: TIME INVARIANT\n(Delaying input delays output equally)');
                    elseif sysIdx == 2 % y = x^2
                        resultStr = sprintf('System: y[n] = x[n]^2\n\nLinearity: NON-LINEAR\n(Fails superposition)\n\nTime Invariance: TIME INVARIANT');
                    elseif sysIdx == 3 % y = n*x
                        resultStr = sprintf('System: y[n] = n*x[n]\n\nLinearity: LINEAR\n\nTime Invariance: TIME VARIANT\n(System behavior changes with time n)');
                    elseif sysIdx == 4 % y = x + 1
                        resultStr = sprintf('System: y[n] = x[n] + 1\n\nLinearity: NON-LINEAR\n(Fails additivity, 0 input != 0 output)\n\nTime Invariance: TIME INVARIANT');
                    end
                    
                    set(txtResult, 'String', resultStr);

                % ---------------------------------------------------------
                % CASE 4: DISCRETE CONVOLUTION [cite: 22]
                % ---------------------------------------------------------
                case 4 
                    h = str2num(txtSig2.String); %#ok<ST2NM> % Impulse response
                    
                    y = conv(x, h);
                    
                    % Create index for convolution result
                    % Length will be Lx + Lh - 1
                    n_y = 0 : (length(y)-1); 
                    
                    % Plotting
                    ax1 = subplot(3,1,1, 'Parent', pnlPlot);
                    stem(ax1, n, x, 'filled'); title(ax1, 'Input x[n]'); grid(ax1, 'on');
                    
                    ax2 = subplot(3,1,2, 'Parent', pnlPlot);
                    stem(ax2, 0:length(h)-1, h, 'filled'); title(ax2, 'Impulse Response h[n]'); grid(ax2, 'on');
                    
                    ax3 = subplot(3,1,3, 'Parent', pnlPlot);
                    stem(ax3, n_y, y, 'm', 'filled', 'LineWidth', 2); 
                    title(ax3, 'Convolution y[n] = x[n] * h[n]'); grid(ax3, 'on');
                    
                    set(txtResult, 'String', 'Convolution Calculated.');
            end
            
        catch ME
            errordlg(['Error in calculation: ' ME.message], 'Code Error');
        end
    end

    % Initialize visibility
    updateVisibility();
end
