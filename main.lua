-- nevermiss — CHAT IA (Groq GPT-OSS — mobile + PC)
-- botão flutuante "IA" abre/fecha a janela | minimiza pra bolinha "IA"
-- suporte a touch (arraste em mobile) | botão COPIAR nas respostas
-- por favor nao tira meus creditos. creditos : 3wost / voidsn5121

local API_KEY = "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"

local MODELS = {
    "openai/gpt-oss-120b",
    "openai/gpt-oss-20b",
}

local INTRO_TEXT = "Lucas Henrique Anes Freitas Castro Barros"
local SPIN_TEXT = "Lucas guloso pelado"

local SYSTEM_PROMPT = "Você é uma assistente formal. Responda SEMPRE em português brasileiro, de forma objetiva, curta e formal. Vá direto ao ponto: no máximo 2-3 frases por resposta, sem enrolação, sem emojis, sem repetir a pergunta. Nunca responda em outro idioma."

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

local request = http_request or request or (http and http.request)

-- ============ COPIAR ============
local function copiarTexto(text)
    if toclipboard then
        toclipboard(text)
        return true
    end
    if setclipboard then
        setclipboard(text)
        return true
    end
    return false
end

-- ============ CHAMADA DA IA ============
local workingModel = nil
local lastError = "nenhuma tentativa registrada"

local function askAI(question)
    local modelsToTry = {}
    if workingModel then
        table.insert(modelsToTry, workingModel)
    end
    for _, m in ipairs(MODELS) do
        if m ~= workingModel then
            table.insert(modelsToTry, m)
        end
    end

    for _, model in ipairs(modelsToTry) do
        local thisBody = HttpService:JSONEncode({
            model = model,
            messages = {
                { role = "system", content = SYSTEM_PROMPT },
                { role = "user", content = question }
            }
        })

        local ok, response = pcall(function()
            return request({
                Url = "https://api.groq.com/openai/v1/chat/completions",
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["Authorization"] = "Bearer " .. API_KEY,
                },
                Body = thisBody,
            })
        end)

        if not ok then
            lastError = model .. " -> rede: " .. tostring(response)
            continue
        end

        local data = response
        if type(response) == "string" then
            local ok2, parsed = pcall(function() return HttpService:JSONDecode(response) end)
            if ok2 then data = parsed end
        end

        if data and data.Body then
            local okBody, decoded = pcall(function()
                return HttpService:JSONDecode(data.Body)
            end)
            if okBody and type(decoded) == "table" then
                data = decoded
            end
        end

        if data and data.error then
            local msg = tostring(data.error.message or data.error)
            lastError = model .. " -> " .. msg
            continue
        end

        if data and data.StatusCode and data.StatusCode >= 400 then
            lastError = model .. " -> HTTP " .. tostring(data.StatusCode)
            continue
        end

        local answer = nil
        if data and data.choices and data.choices[1] and data.choices[1].message then
            answer = data.choices[1].message.content
        end

        if answer and answer ~= "" then
            workingModel = model
            return answer
        end

        lastError = model .. " -> sem texto na resposta"
    end

    return "ERRO — motivo: " .. lastError
end

-- ============ GUI ============
local gui = Instance.new("ScreenGui")
gui.Name = "ChatIA"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local popupFrame = Instance.new("Frame")
popupFrame.Size = UDim2.new(0, 0, 0, 0)
popupFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
popupFrame.AnchorPoint = Vector2.new(0.5, 0.5)
popupFrame.BackgroundTransparency = 0.3
popupFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
popupFrame.Parent = gui

local popupText = Instance.new("TextLabel")
popupText.Size = UDim2.new(1, 0, 1, 0)
popupText.BackgroundTransparency = 1
popupText.TextColor3 = Color3.fromRGB(255, 255, 255)
popupText.TextScaled = true
popupText.Font = Enum.Font.GothamBold
popupText.Text = INTRO_TEXT
popupText.Parent = popupFrame

local loadTween = TweenService:Create(
    popupFrame,
    TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    { Size = UDim2.new(0, 300, 0, 50) }
)
loadTween:Play()
loadTween.Completed:Connect(function()
    task.delay(1, function()
        local fadeTween = TweenService:Create(
            popupFrame,
            TweenInfo.new(0.5),
            { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }
        )
        fadeTween:Play()
        fadeTween.Completed:Connect(function()
            popupFrame:Destroy()
        end)
    end)
end)

local spinningText = Instance.new("TextLabel")
spinningText.Size = UDim2.new(0, 200, 0, 30)
spinningText.Position = UDim2.new(1, -210, 1, -40)
spinningText.BackgroundTransparency = 1
spinningText.TextColor3 = Color3.fromRGB(255, 255, 255)
spinningText.TextScaled = true
spinningText.Font = Enum.Font.GothamBold
spinningText.Text = SPIN_TEXT
spinningText.Parent = gui

RunService.RenderStepped:Connect(function(dt)
    spinningText.Rotation = spinningText.Rotation + dt * 30
end)

-- ============ JANELA DO CHAT (mobile: menor e redimensionada) ============
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

local window = Instance.new("Frame")
window.Size = isMobile and UDim2.new(0, 280, 0, 320) or UDim2.new(0, 380, 0, 420)
window.Position = isMobile and UDim2.new(0.5, -140, 0.5, -160) or UDim2.new(0.5, -190, 0.5, -210)
window.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
window.BackgroundTransparency = 0.15
window.BorderSizePixel = 0
window.Visible = false
window.Active = true
window.Parent = gui

local winCorner = Instance.new("UICorner", window)
winCorner.CornerRadius = UDim.new(0, 8)

local winStroke = Instance.new("UIStroke", window)
winStroke.Color = Color3.fromRGB(60, 60, 60)
winStroke.Thickness = 1
winStroke.Transparency = 0.4

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
title.BackgroundTransparency = 0.3
title.Text = "  CHAT IA"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 13
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = window

local titleCorner = Instance.new("UICorner", title)
titleCorner.CornerRadius = UDim.new(0, 8)

-- botão minimizar dentro da janela
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 24, 0, 24)
minBtn.Position = UDim2.new(1, -28, 0, 3)
minBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Text = "–"
minBtn.TextSize = 14
minBtn.Font = Enum.Font.GothamBold
minBtn.Parent = title

-- drag da janela (mouse + touch)
do
    local dragging = false
    local dragStart, startPos

    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = window.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- scroll do chat
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -16, 1, -100)
scroll.Position = UDim2.new(0, 8, 0, 36)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = window

local listLayout = Instance.new("UIListLayout", scroll)
listLayout.Padding = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

local msgCount = 0

-- mensagem da IA: balão + botão COPIAR
local function addAIMessage(text)
    msgCount = msgCount + 1
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -8, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.BackgroundTransparency = 1
    container.LayoutOrder = msgCount
    container.Parent = scroll

    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, 0, 0, 0)
    msg.AutomaticSize = Enum.AutomaticSize.Y
    msg.BackgroundColor3 = Color3.fromRGB(30, 40, 30)
    msg.BackgroundTransparency = 0.5
    msg.TextColor3 = Color3.fromRGB(120, 255, 120)
    msg.TextSize = 13
    msg.Font = Enum.Font.Gotham
    msg.Text = "IA: " .. text
    msg.TextWrapped = true
    msg.TextXAlignment = Enum.TextXAlignment.Left
    msg.Parent = container

    local copyBtn = Instance.new("TextButton")
    copyBtn.Size = UDim2.new(0, 90, 0, 22)
    copyBtn.Position = UDim2.new(0, 0, 1, 2)
    copyBtn.BackgroundColor3 = Color3.fromRGB(25, 35, 25)
    copyBtn.TextColor3 = Color3.fromRGB(150, 220, 150)
    copyBtn.Text = "COPIAR"
    copyBtn.TextSize = 11
    copyBtn.Font = Enum.Font.GothamBold
    copyBtn.Parent = container

    local copyCorner = Instance.new("UICorner", copyBtn)
    copyCorner.CornerRadius = UDim.new(0, 5)

    copyBtn.MouseButton1Click:Connect(function()
        local ok = copiarTexto(text)
        if ok then
            copyBtn.Text = "COPIADO!"
            copyBtn.TextColor3 = Color3.fromRGB(120, 255, 120)
        else
            copyBtn.Text = "SEM SUPORTE"
            copyBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
        end
        task.delay(1.5, function()
            copyBtn.Text = "COPIAR"
            copyBtn.TextColor3 = Color3.fromRGB(150, 220, 150)
        end)
    end)

    local spacer = Instance.new("Frame")
    spacer.Size = UDim2.new(1, 0, 0, 28)
    spacer.Position = UDim2.new(0, 0, 1, 2)
    spacer.BackgroundTransparency = 1
    spacer.Parent = container

    scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    scroll.CanvasPosition = Vector2.new(0, listLayout.AbsoluteContentSize.Y)
end

-- mensagem do usuário
local function addUserMessage(text)
    msgCount = msgCount + 1
    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, -8, 0, 0)
    msg.AutomaticSize = Enum.AutomaticSize.Y
    msg.BackgroundTransparency = 1
    msg.TextColor3 = Color3.fromRGB(150, 200, 255)
    msg.TextSize = 13
    msg.Font = Enum.Font.Gotham
    msg.Text = "VOCÊ: " .. text
    msg.TextWrapped = true
    msg.TextXAlignment = Enum.TextXAlignment.Left
    msg.LayoutOrder = msgCount
    msg.Parent = scroll

    scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    scroll.CanvasPosition = Vector2.new(0, listLayout.AbsoluteContentSize.Y)
end

local inputBox = Instance.new("TextBox")
inputBox.Size = UDim2.new(1, -70, 0, 30)
inputBox.Position = UDim2.new(0, 8, 1, -38)
inputBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
inputBox.PlaceholderText = "pergunte qualquer coisa..."
inputBox.Text = ""
inputBox.TextSize = 13
inputBox.Font = Enum.Font.Gotham
inputBox.ClearTextOnFocus = false
inputBox.Parent = window

local inputCorner = Instance.new("UICorner", inputBox)
inputCorner.CornerRadius = UDim.new(0, 6)

local sendBtn = Instance.new("TextButton")
sendBtn.Size = UDim2.new(0, 56, 0, 30)
sendBtn.Position = UDim2.new(1, -64, 1, -38)
sendBtn.BackgroundColor3 = Color3.fromRGB(30, 60, 30)
sendBtn.TextColor3 = Color3.fromRGB(120, 255, 120)
sendBtn.Text = "ENVIAR"
sendBtn.TextSize = 11
sendBtn.Font = Enum.Font.GothamBold
sendBtn.Parent = window

local sendCorner = Instance.new("UICorner", sendBtn)
sendCorner.CornerRadius = UDim.new(0, 6)

-- ============ ENVIO ============
local busy = false

local function send()
    if busy then return end
    local question = inputBox.Text
    if question == "" then return end

    inputBox.Text = ""
    addUserMessage(question)
    busy = true
    sendBtn.Text = "..."

    task.spawn(function()
        local answer = askAI(question)
        addAIMessage(answer)
        busy = false
        sendBtn.Text = "ENVIAR"
    end)
end

sendBtn.MouseButton1Click:Connect(send)

inputBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        send()
    end
end)

-- ============ BOLINHA FLUTUANTE "IA" (abre/fecha/minimiza) ============
local floatBtn = Instance.new("TextButton")
floatBtn.Size = UDim2.new(0, 48, 0, 48)
floatBtn.Position = UDim2.new(0, 10, 0.5, -24)
floatBtn.BackgroundColor3 = Color3.fromRGB(30, 60, 30)
floatBtn.TextColor3 = Color3.fromRGB(120, 255, 120)
floatBtn.Text = "IA"
floatBtn.TextSize = 16
floatBtn.Font = Enum.Font.GothamBold
floatBtn.Parent = gui

local floatCorner = Instance.new("UICorner", floatBtn)
floatCorner.CornerRadius = UDim.new(1, 0)

local floatStroke = Instance.new("UIStroke", floatBtn)
floatStroke.Color = Color3.fromRGB(0, 0, 0)
floatStroke.Thickness = 1

-- bolinha minimizada (SA)
local dotBtn = Instance.new("TextButton")
dotBtn.Size = UDim2.new(0, 45, 0, 45)
dotBtn.Position = UDim2.new(0, 10, 0.5, -22)
dotBtn.BackgroundColor3 = Color3.fromRGB(30, 60, 30)
dotBtn.TextColor3 = Color3.fromRGB(120, 255, 120)
dotBtn.Text = "IA"
dotBtn.TextSize = 14
dotBtn.Font = Enum.Font.GothamBold
dotBtn.Visible = false
dotBtn.Parent = gui

local dotCorner = Instance.new("UICorner", dotBtn)
dotCorner.CornerRadius = UDim.new(1, 0)

-- drag universal (mouse + touch) + lógica de clique
local function makeDraggable(button, onClick, dragThreshold)
    local dragging = false
    local dragStart, startPos
    local moved = false

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = button.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            if delta.Magnitude > dragThreshold then
                moved = true
            end
            button.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            if dragging and not moved and onClick then
                onClick()
            end
            dragging = false
        end
    end)
end

-- ============ BOLINHAS + JANELA (uma visível por vez) ============
-- estado: janela aberta = nada de bolinha | fechada = bolinha "IA"
-- minimizada = bolinha "SA"

local function showChat()
    window.Visible = true
    dotBtn.Visible = false
    floatBtn.Visible = false
end

local function minimizeChat()
    window.Visible = false
    dotBtn.Visible = true   -- minimizada: "SA" (volta pro chat)
    floatBtn.Visible = false
end

local function closeChat()
    window.Visible = false
    dotBtn.Visible = false
    floatBtn.Visible = true -- fechada: "IA" (abre de novo)
end

-- botão flutuante IA: clique abre o chat
makeDraggable(floatBtn, showChat, 8)

-- botão minimizar da janela: minimiza (bolinha SA)
minBtn.MouseButton1Click:Connect(minimizeChat)

-- bolinha SA: clique reabre o chat
makeDraggable(dotBtn, showChat, 8)

-- estado inicial: fechado — só a bolinha IA aparece
closeChat()
