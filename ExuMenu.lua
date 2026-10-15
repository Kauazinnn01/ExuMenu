-- ██████████████████████████████████████████████████████
-- █                   EXU MENU v1.0                    █
-- █           Murder Mystery 2 - Script OP             █
-- █         Feito para executores (Synapse/SW)         █
-- ██████████████████████████████████████████████████████

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ══════════════════════════════════════════════
--              ESTADO GLOBAL
-- ══════════════════════════════════════════════
local State = {
    -- Visual
    ESP_Habilitado     = false,
    ESP_Caixas         = true,
    ESP_Nomes          = true,
    ESP_Funcoes        = true,
    ESP_Tracers        = false,
    ESP_Distancia      = true,
    DestaqueMurderer   = true,
    DestaqueSheriff    = true,
    ChaoESP            = false,

    -- Jogadores
    SpeedHack          = false,
    VelocidadeValor    = 32,
    NoClip             = false,
    InfiniteJump       = false,
    AntiMorte          = false,
    TeleportJogador    = "",

    -- Rodada
    RevealMurderer     = false,
    RevealSheriff      = false,
    AutoColetarMoedas  = false,
    AutoPegarArma      = false,

    -- Itens
    AutoColetarItens   = false,
    ItemESP            = false,

    -- Mira
    Aimbot             = false,
    AimbotFOV          = 150,
    AimbotSmooth       = 0.15,
    AimbotOsso         = "Head",
    SilentAim          = false,
    AimKey             = Enum.UserInputType.MouseButton2,

    -- Info interna
    MurdererPlayer     = nil,
    SheriffPlayer      = nil,
    Connections        = {},
    ESPObjects         = {},
}

-- ══════════════════════════════════════════════
--              UTILITÁRIOS
-- ══════════════════════════════════════════════
local function ObterPersonagem(plr)
    return plr and plr.Character
end

local function ObterRaiz(plr)
    local char = ObterPersonagem(plr)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function ObterHumanoid(plr)
    local char = ObterPersonagem(plr)
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function EstaVivo(plr)
    local hum = ObterHumanoid(plr)
    return hum and hum.Health > 0
end

local function MundoParaTela(pos)
    local ok, tela = pcall(function()
        return Camera:WorldToViewportPoint(pos)
    end)
    if ok then return tela end
    return nil
end

local function ObterFuncaoJogador(plr)
    -- Detecta papel via ferramentas no personagem
    local char = ObterPersonagem(plr)
    if not char then return "INOCENTE" end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local nome = tool.Name:lower()
            if nome:find("knife") or nome:find("faca") then
                return "ASSASSINO"
            elseif nome:find("gun") or nome:find("sheriff") or nome:find("revolver") then
                return "XERIFE"
            end
        end
    end
    -- Backup: backpack
    local bp = plr:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            local nome = tool.Name:lower()
            if nome:find("knife") or nome:find("faca") then
                return "ASSASSINO"
            elseif nome:find("gun") or nome:find("sheriff") or nome:find("revolver") then
                return "XERIFE"
            end
        end
    end
    return "INOCENTE"
end

local function ObterCorFuncao(funcao)
    if funcao == "ASSASSINO" then return Color3.fromRGB(255, 60, 60)
    elseif funcao == "XERIFE" then return Color3.fromRGB(60, 180, 255)
    else return Color3.fromRGB(60, 255, 120) end
end

local function DistanciaAte(plr)
    local raiz = ObterRaiz(plr)
    local meuraiz = ObterRaiz(LocalPlayer)
    if not raiz or not meuraiz then return 0 end
    return math.floor((raiz.Position - meuraiz.Position).Magnitude)
end

-- ══════════════════════════════════════════════
--              ESP SYSTEM
-- ══════════════════════════════════════════════
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "ExuESP"
ESPFolder.Parent = CoreGui

local function CriarESPJogador(plr)
    if plr == LocalPlayer then return end
    if State.ESPObjects[plr] then return end

    local obj = {}

    -- Caixa
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.fromRGB(255,255,255)
    box.Thickness = 1.5
    box.Filled = false
    obj.Box = box

    -- Contorno da caixa
    local boxOutline = Drawing.new("Square")
    boxOutline.Visible = false
    boxOutline.Color = Color3.fromRGB(0,0,0)
    boxOutline.Thickness = 3
    boxOutline.Filled = false
    obj.BoxOutline = boxOutline

    -- Nome
    local nome = Drawing.new("Text")
    nome.Visible = false
    nome.Size = 14
    nome.Center = true
    nome.Outline = true
    nome.OutlineColor = Color3.fromRGB(0,0,0)
    obj.Nome = nome

    -- Função (Assassino/Xerife/Inocente)
    local funcaoLabel = Drawing.new("Text")
    funcaoLabel.Visible = false
    funcaoLabel.Size = 13
    funcaoLabel.Center = true
    funcaoLabel.Outline = true
    funcaoLabel.OutlineColor = Color3.fromRGB(0,0,0)
    obj.FuncaoLabel = funcaoLabel

    -- Distância
    local dist = Drawing.new("Text")
    dist.Visible = false
    dist.Size = 12
    dist.Center = true
    dist.Outline = true
    dist.OutlineColor = Color3.fromRGB(0,0,0)
    dist.Color = Color3.fromRGB(200,200,200)
    obj.Dist = dist

    -- Tracer
    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Thickness = 1
    tracer.Color = Color3.fromRGB(255,255,255)
    obj.Tracer = tracer

    State.ESPObjects[plr] = obj
end

local function RemoverESPJogador(plr)
    local obj = State.ESPObjects[plr]
    if not obj then return end
    for _, v in pairs(obj) do
        if v and v.Remove then pcall(function() v:Remove() end) end
    end
    State.ESPObjects[plr] = nil
end

local function AtualizarESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            CriarESPJogador(plr)
        end
    end

    for plr, obj in pairs(State.ESPObjects) do
        local visivel = State.ESP_Habilitado and EstaVivo(plr)
        local char = ObterPersonagem(plr)

        if not visivel or not char then
            for _, d in pairs(obj) do
                if d and d.Visible ~= nil then d.Visible = false end
            end
        else
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local head = char:FindFirstChild("Head")
            if not hrp or not head then
                for _, d in pairs(obj) do
                    if d and d.Visible ~= nil then d.Visible = false end
                end
            else
                local posHead, visHead = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.7, 0))
                local posFootVec = hrp.Position - Vector3.new(0, 3, 0)
                local posFoot = Camera:WorldToViewportPoint(posFootVec)

                if not visHead then
                    for _, d in pairs(obj) do
                        if d and d.Visible ~= nil then d.Visible = false end
                    end
                else
                    local altura = math.abs(posHead.Y - posFoot.Y)
                    local largura = altura * 0.55
                    local funcao = ObterFuncaoJogador(plr)
                    local cor = ObterCorFuncao(funcao)

                    -- Caixa
                    if State.ESP_Caixas then
                        obj.BoxOutline.Visible = true
                        obj.BoxOutline.Size = Vector2.new(largura + 2, altura + 2)
                        obj.BoxOutline.Position = Vector2.new(posHead.X - largura/2 - 1, posHead.Y - 1)

                        obj.Box.Visible = true
                        obj.Box.Color = cor
                        obj.Box.Size = Vector2.new(largura, altura)
                        obj.Box.Position = Vector2.new(posHead.X - largura/2, posHead.Y)
                    else
                        obj.Box.Visible = false
                        obj.BoxOutline.Visible = false
                    end

                    -- Nome
                    if State.ESP_Nomes then
                        obj.Nome.Visible = true
                        obj.Nome.Text = plr.Name
                        obj.Nome.Color = cor
                        obj.Nome.Position = Vector2.new(posHead.X, posHead.Y - 18)
                    else
                        obj.Nome.Visible = false
                    end

                    -- Função
                    if State.ESP_Funcoes then
                        obj.FuncaoLabel.Visible = true
                        obj.FuncaoLabel.Text = funcao
                        obj.FuncaoLabel.Color = cor
                        obj.FuncaoLabel.Position = Vector2.new(posHead.X, posHead.Y - 32)
                    else
                        obj.FuncaoLabel.Visible = false
                    end

                    -- Distância
                    if State.ESP_Distancia then
                        local d = DistanciaAte(plr)
                        obj.Dist.Visible = true
                        obj.Dist.Text = d .. "m"
                        obj.Dist.Position = Vector2.new(posHead.X, posFoot.Y + 2)
                    else
                        obj.Dist.Visible = false
                    end

                    -- Tracer
                    if State.ESP_Tracers then
                        obj.Tracer.Visible = true
                        obj.Tracer.Color = cor
                        obj.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        obj.Tracer.To = Vector2.new(posHead.X, posHead.Y)
                    else
                        obj.Tracer.Visible = false
                    end
                end
            end
        end
    end
end

-- ══════════════════════════════════════════════
--              AIMBOT / SILENT AIM
-- ══════════════════════════════════════════════
local function ObterAlvoMaisProximo()
    local melhor = nil
    local menorDist = math.huge
    local centro = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and EstaVivo(plr) then
            local char = ObterPersonagem(plr)
            if char then
                local osso = char:FindFirstChild(State.AimbotOsso) or char:FindFirstChild("Head")
                if osso then
                    local tela, visible = Camera:WorldToViewportPoint(osso.Position)
                    if visible then
                        local dist2D = (Vector2.new(tela.X, tela.Y) - centro).Magnitude
                        if dist2D < State.AimbotFOV and dist2D < menorDist then
                            menorDist = dist2D
                            melhor = plr
                        end
                    end
                end
            end
        end
    end
    return melhor
end

local AimbotConn
local function IniciarAimbot()
    if AimbotConn then AimbotConn:Disconnect() end
    AimbotConn = RunService.RenderStepped:Connect(function()
        if not State.Aimbot then return end
        if not UserInputService:IsMouseButtonPressed(State.AimKey) then return end

        local alvo = ObterAlvoMaisProximo()
        if not alvo then return end
        local char = ObterPersonagem(alvo)
        if not char then return end
        local osso = char:FindFirstChild(State.AimbotOsso) or char:FindFirstChild("Head")
        if not osso then return end

        local direcao = CFrame.new(Camera.CFrame.Position, osso.Position)
        Camera.CFrame = Camera.CFrame:Lerp(direcao, State.AimbotSmooth)
    end)
end
IniciarAimbot()

-- Silent Aim: substitui o alvo da bala
local SilentAimConn
local function IniciarSilentAim()
    if SilentAimConn then SilentAimConn:Disconnect() end
    -- Hook no FireServer da ferramenta atual
    local function HookTool(tool)
        local re = tool:FindFirstChild("RemoteEvent") or tool:FindFirstChildOfClass("RemoteEvent")
        if not re then return end
        local oldFire = re.FireServer
        re.FireServer = function(self, ...)
            if not State.SilentAim then return oldFire(self, ...) end
            local alvo = ObterAlvoMaisProximo()
            if not alvo then return oldFire(self, ...) end
            local char = ObterPersonagem(alvo)
            local osso = char and (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"))
            if osso then
                return oldFire(self, osso.Position)
            end
            return oldFire(self, ...)
        end
    end

    LocalPlayer.CharacterAdded:Connect(function(char)
        char.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then HookTool(child) end
        end)
    end)
    if LocalPlayer.Character then
        for _, child in ipairs(LocalPlayer.Character:GetChildren()) do
            if child:IsA("Tool") then HookTool(child) end
        end
    end
end
IniciarSilentAim()

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Thickness = 1
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Filled = false
FOVCircle.NumSides = 64

RunService.RenderStepped:Connect(function()
    if State.Aimbot then
        FOVCircle.Visible = true
        FOVCircle.Radius = State.AimbotFOV
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    else
        FOVCircle.Visible = false
    end
end)

-- ══════════════════════════════════════════════
--              SPEED HACK
-- ══════════════════════════════════════════════
local SpeedConn
local function AtualizarSpeed()
    if SpeedConn then SpeedConn:Disconnect() SpeedConn = nil end
    if State.SpeedHack then
        SpeedConn = RunService.Heartbeat:Connect(function()
            local hum = ObterHumanoid(LocalPlayer)
            if hum then hum.WalkSpeed = State.VelocidadeValor end
        end)
    else
        local hum = ObterHumanoid(LocalPlayer)
        if hum then hum.WalkSpeed = 16 end
    end
end

-- ══════════════════════════════════════════════
--              INFINITE JUMP
-- ══════════════════════════════════════════════
UserInputService.JumpRequest:Connect(function()
    if State.InfiniteJump then
        local hum = ObterHumanoid(LocalPlayer)
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ══════════════════════════════════════════════
--              NOCLIP
-- ══════════════════════════════════════════════
RunService.Stepped:Connect(function()
    if State.NoClip then
        local char = ObterPersonagem(LocalPlayer)
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- ══════════════════════════════════════════════
--              AUTO COLETAR MOEDAS
-- ══════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if State.AutoColetarMoedas then
        local meuraiz = ObterRaiz(LocalPlayer)
        if not meuraiz then return end
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name:lower():find("coin") or obj.Name:lower():find("moeda") then
                if obj:IsA("BasePart") or obj:IsA("MeshPart") then
                    local d = (obj.Position - meuraiz.Position).Magnitude
                    if d < 50 then
                        meuraiz.CFrame = CFrame.new(obj.Position)
                    end
                end
            end
        end
    end
end)

-- ══════════════════════════════════════════════
--              REVELAR ASSASSINO / XERIFE
-- ══════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    State.MurdererPlayer = nil
    State.SheriffPlayer = nil
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local f = ObterFuncaoJogador(plr)
            if f == "ASSASSINO" then State.MurdererPlayer = plr end
            if f == "XERIFE" then State.SheriffPlayer = plr end
        end
    end
end)

-- ══════════════════════════════════════════════
--              TELEPORT PARA JOGADOR
-- ══════════════════════════════════════════════
local function TeleportarPara(nome)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Name:lower():find(nome:lower()) then
            local raiz = ObterRaiz(plr)
            local meuraiz = ObterRaiz(LocalPlayer)
            if raiz and meuraiz then
                meuraiz.CFrame = raiz.CFrame + Vector3.new(0, 3, 0)
                return true
            end
        end
    end
    return false
end

-- ══════════════════════════════════════════════
--              ANTI MORTE (God Mode tentativa)
-- ══════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if State.AntiMorte then
        local hum = ObterHumanoid(LocalPlayer)
        if hum then
            hum.Health = hum.MaxHealth
        end
    end
end)

-- ══════════════════════════════════════════════
--                   GUI — EXU MENU
-- ══════════════════════════════════════════════
-- Limpar GUI antiga se existir
if CoreGui:FindFirstChild("ExuMenuGUI") then
    CoreGui:FindFirstChild("ExuMenuGUI"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ExuMenuGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

-- Janela principal
local Janela = Instance.new("Frame")
Janela.Name = "Janela"
Janela.Size = UDim2.new(0, 680, 0, 480)
Janela.Position = UDim2.new(0.5, -340, 0.5, -240)
Janela.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Janela.BorderSizePixel = 0
Janela.ClipsDescendants = true
Janela.Parent = ScreenGui

Instance.new("UICorner", Janela).CornerRadius = UDim.new(0, 10)

-- Borda sutil
local BorderFrame = Instance.new("Frame")
BorderFrame.Size = UDim2.new(1, 2, 1, 2)
BorderFrame.Position = UDim2.new(0, -1, 0, -1)
BorderFrame.BackgroundColor3 = Color3.fromRGB(180, 40, 60)
BorderFrame.BorderSizePixel = 0
BorderFrame.ZIndex = 0
BorderFrame.Parent = Janela
Instance.new("UICorner", BorderFrame).CornerRadius = UDim.new(0, 11)

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 52)
Header.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
Header.BorderSizePixel = 0
Header.Parent = Janela

-- Logo S
local LogoCircle = Instance.new("Frame")
LogoCircle.Size = UDim2.new(0, 32, 0, 32)
LogoCircle.Position = UDim2.new(0, 14, 0.5, -16)
LogoCircle.BackgroundColor3 = Color3.fromRGB(180, 40, 60)
LogoCircle.BorderSizePixel = 0
LogoCircle.Parent = Header
Instance.new("UICorner", LogoCircle).CornerRadius = UDim.new(0, 6)

local LogoText = Instance.new("TextLabel")
LogoText.Size = UDim2.new(1, 0, 1, 0)
LogoText.Text = "E"
LogoText.TextColor3 = Color3.fromRGB(255,255,255)
LogoText.TextSize = 18
LogoText.Font = Enum.Font.GothamBold
LogoText.BackgroundTransparency = 1
LogoText.Parent = LogoCircle

-- Título
local TituloLabel = Instance.new("TextLabel")
TituloLabel.Size = UDim2.new(0, 160, 0, 20)
TituloLabel.Position = UDim2.new(0, 54, 0, 10)
TituloLabel.Text = "Exu Menu"
TituloLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TituloLabel.TextSize = 15
TituloLabel.Font = Enum.Font.GothamBold
TituloLabel.BackgroundTransparency = 1
TituloLabel.TextXAlignment = Enum.TextXAlignment.Left
TituloLabel.Parent = Header

local SubLabel = Instance.new("TextLabel")
SubLabel.Size = UDim2.new(0, 160, 0, 16)
SubLabel.Position = UDim2.new(0, 54, 0, 28)
SubLabel.Text = "MM2 — v1.0"
SubLabel.TextColor3 = Color3.fromRGB(140, 80, 100)
SubLabel.TextSize = 12
SubLabel.Font = Enum.Font.Gotham
SubLabel.BackgroundTransparency = 1
SubLabel.TextXAlignment = Enum.TextXAlignment.Left
SubLabel.Parent = Header

-- Botão fechar
local BtnFechar = Instance.new("TextButton")
BtnFechar.Size = UDim2.new(0, 28, 0, 28)
BtnFechar.Position = UDim2.new(1, -42, 0.5, -14)
BtnFechar.Text = "×"
BtnFechar.TextColor3 = Color3.fromRGB(200, 200, 200)
BtnFechar.TextSize = 20
BtnFechar.Font = Enum.Font.GothamBold
BtnFechar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
BtnFechar.BorderSizePixel = 0
BtnFechar.Parent = Header
Instance.new("UICorner", BtnFechar).CornerRadius = UDim.new(0, 6)

-- Botão minimizar
local BtnMin = Instance.new("TextButton")
BtnMin.Size = UDim2.new(0, 28, 0, 28)
BtnMin.Position = UDim2.new(1, -76, 0.5, -14)
BtnMin.Text = "—"
BtnMin.TextColor3 = Color3.fromRGB(200, 200, 200)
BtnMin.TextSize = 14
BtnMin.Font = Enum.Font.GothamBold
BtnMin.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
BtnMin.BorderSizePixel = 0
BtnMin.Parent = Header
Instance.new("UICorner", BtnMin).CornerRadius = UDim.new(0, 6)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 160, 1, -52)
Sidebar.Position = UDim2.new(0, 0, 0, 52)
Sidebar.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Janela

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Padding = UDim.new(0, 2)
SidebarLayout.Parent = Sidebar

local SidePad = Instance.new("UIPadding")
SidePad.PaddingTop = UDim.new(0, 10)
SidePad.PaddingLeft = UDim.new(0, 8)
SidePad.PaddingRight = UDim.new(0, 8)
SidePad.Parent = Sidebar

-- Área de conteúdo
local Conteudo = Instance.new("Frame")
Conteudo.Size = UDim2.new(1, -160, 1, -52)
Conteudo.Position = UDim2.new(0, 160, 0, 52)
Conteudo.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
Conteudo.BorderSizePixel = 0
Conteudo.ClipsDescendants = true
Conteudo.Parent = Janela

-- Separador vertical
local Sep = Instance.new("Frame")
Sep.Size = UDim2.new(0, 1, 1, -52)
Sep.Position = UDim2.new(0, 160, 0, 52)
Sep.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
Sep.BorderSizePixel = 0
Sep.Parent = Janela

-- ═══════════════════════════════════════
--   HELPER: criar toggle, slider, botão
-- ═══════════════════════════════════════
local function CriarPagina(nome)
    local page = Instance.new("ScrollingFrame")
    page.Name = nome
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = Color3.fromRGB(180, 40, 60)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = Conteudo

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = page

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 14)
    pad.PaddingLeft = UDim.new(0, 14)
    pad.PaddingRight = UDim.new(0, 14)
    pad.PaddingBottom = UDim.new(0, 14)
    pad.Parent = page

    return page
end

local function CriarSecao(parent, titulo)
    local sec = Instance.new("TextLabel")
    sec.Size = UDim2.new(1, 0, 0, 24)
    sec.Text = "  " .. titulo:upper()
    sec.TextColor3 = Color3.fromRGB(180, 40, 60)
    sec.TextSize = 11
    sec.Font = Enum.Font.GothamBold
    sec.BackgroundTransparency = 1
    sec.TextXAlignment = Enum.TextXAlignment.Left
    sec.LayoutOrder = 0
    sec.Parent = parent
    return sec
end

local function CriarToggle(parent, labelText, estadoInicial, onChange, order)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 38)
    frame.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order or 1
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 7)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(210, 210, 210)
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local togBG = Instance.new("Frame")
    togBG.Size = UDim2.new(0, 38, 0, 20)
    togBG.Position = UDim2.new(1, -48, 0.5, -10)
    togBG.BackgroundColor3 = estadoInicial and Color3.fromRGB(180, 40, 60) or Color3.fromRGB(45, 45, 55)
    togBG.BorderSizePixel = 0
    togBG.Parent = frame
    Instance.new("UICorner", togBG).CornerRadius = UDim.new(1, 0)

    local togCircle = Instance.new("Frame")
    togCircle.Size = UDim2.new(0, 14, 0, 14)
    togCircle.Position = estadoInicial and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    togCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    togCircle.BorderSizePixel = 0
    togCircle.Parent = togBG
    Instance.new("UICorner", togCircle).CornerRadius = UDim.new(1, 0)

    local estado = estadoInicial
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = frame

    btn.MouseButton1Click:Connect(function()
        estado = not estado
        local tween = TweenService:Create(togBG, TweenInfo.new(0.15), {
            BackgroundColor3 = estado and Color3.fromRGB(180, 40, 60) or Color3.fromRGB(45, 45, 55)
        })
        tween:Play()
        local tween2 = TweenService:Create(togCircle, TweenInfo.new(0.15), {
            Position = estado and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        })
        tween2:Play()
        onChange(estado)
    end)

    return frame
end

local function CriarSlider(parent, labelText, min, max, valorInicial, onChange, order)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 54)
    frame.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order or 1
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 7)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 0, 22)
    label.Position = UDim2.new(0, 12, 0, 6)
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(210, 210, 210)
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local valorLabel = Instance.new("TextLabel")
    valorLabel.Size = UDim2.new(0, 58, 0, 22)
    valorLabel.Position = UDim2.new(1, -68, 0, 6)
    valorLabel.Text = tostring(valorInicial)
    valorLabel.TextColor3 = Color3.fromRGB(180, 40, 60)
    valorLabel.TextSize = 13
    valorLabel.Font = Enum.Font.GothamBold
    valorLabel.BackgroundTransparency = 1
    valorLabel.TextXAlignment = Enum.TextXAlignment.Right
    valorLabel.Parent = frame

    local trackBG = Instance.new("Frame")
    trackBG.Size = UDim2.new(1, -24, 0, 6)
    trackBG.Position = UDim2.new(0, 12, 0, 36)
    trackBG.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    trackBG.BorderSizePixel = 0
    trackBG.Parent = frame
    Instance.new("UICorner", trackBG).CornerRadius = UDim.new(1, 0)

    local pct = (valorInicial - min) / (max - min)
    local trackFill = Instance.new("Frame")
    trackFill.Size = UDim2.new(pct, 0, 1, 0)
    trackFill.BackgroundColor3 = Color3.fromRGB(180, 40, 60)
    trackFill.BorderSizePixel = 0
    trackFill.Parent = trackBG
    Instance.new("UICorner", trackFill).CornerRadius = UDim.new(1, 0)

    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.new(0, 14, 0, 14)
    thumb.Position = UDim2.new(pct, -7, 0.5, -7)
    thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    thumb.BorderSizePixel = 0
    thumb.Parent = trackBG
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

    local dragging = false
    thumb.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local abs = trackBG.AbsolutePosition
            local sz = trackBG.AbsoluteSize
            local rel = math.clamp((inp.Position.X - abs.X) / sz.X, 0, 1)
            local valor = math.floor(min + rel * (max - min))
            trackFill.Size = UDim2.new(rel, 0, 1, 0)
            thumb.Position = UDim2.new(rel, -7, 0.5, -7)
            valorLabel.Text = tostring(valor)
            onChange(valor)
        end
    end)

    return frame
end

local function CriarBotao(parent, labelText, onClick, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = Color3.fromRGB(180, 40, 60)
    btn.BorderSizePixel = 0
    btn.Text = labelText
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.LayoutOrder = order or 1
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)

    btn.MouseButton1Click:Connect(onClick)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(210, 50, 70)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(180, 40, 60)}):Play()
    end)
    return btn
end

local function CriarInput(parent, placeholder, onChange, order)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 36)
    frame.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order or 1
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 7)

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -16, 1, 0)
    input.Position = UDim2.new(0, 8, 0, 0)
    input.PlaceholderText = placeholder
    input.Text = ""
    input.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
    input.TextColor3 = Color3.fromRGB(220, 220, 220)
    input.TextSize = 13
    input.Font = Enum.Font.Gotham
    input.BackgroundTransparency = 1
    input.TextXAlignment = Enum.TextXAlignment.Left
    input.Parent = frame

    input:GetPropertyChangedSignal("Text"):Connect(function()
        onChange(input.Text)
    end)

    return frame, input
end

-- ═══════════════════════════════
--         INFO LATERAL (rodada)
-- ═══════════════════════════════
local InfoPanel = Instance.new("Frame")
InfoPanel.Size = UDim2.new(0, 200, 0, 70)
InfoPanel.Position = UDim2.new(1, -210, 0, 62)
InfoPanel.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
InfoPanel.BorderSizePixel = 0
InfoPanel.Parent = ScreenGui
Instance.new("UICorner", InfoPanel).CornerRadius = UDim.new(0, 8)

local InfoLayout = Instance.new("UIListLayout")
InfoLayout.SortOrder = Enum.SortOrder.LayoutOrder
InfoLayout.Padding = UDim.new(0, 2)
InfoLayout.Parent = InfoPanel

local InfoPad = Instance.new("UIPadding")
InfoPad.PaddingAll = UDim.new(0, 8)
InfoPad.Parent = InfoPanel

local function CriarInfoLabel(texto, cor, order)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 18)
    l.Text = texto
    l.TextColor3 = cor or Color3.fromRGB(200, 200, 200)
    l.TextSize = 12
    l.Font = Enum.Font.Gotham
    l.BackgroundTransparency = 1
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.LayoutOrder = order
    l.Parent = InfoPanel
    return l
end

local LabelMapa = CriarInfoLabel("Mapa: Carregando...", Color3.fromRGB(150,150,180), 1)
local LabelJogadores = CriarInfoLabel("Jogadores: --", Color3.fromRGB(150,150,180), 2)
local LabelMurderer = CriarInfoLabel("Assassino: ?", Color3.fromRGB(255,80,80), 3)
local LabelSheriff = CriarInfoLabel("Xerife: ?", Color3.fromRGB(80,160,255), 4)

RunService.Heartbeat:Connect(function()
    local total = #Players:GetPlayers()
    LabelJogadores.Text = "Jogadores: " .. total

    local mapFrame = Workspace:FindFirstChild("Map") or Workspace:FindFirstChild("MapModel")
    if mapFrame then LabelMapa.Text = "Mapa: " .. mapFrame.Name
    else LabelMapa.Text = "Mapa: Desconhecido" end

    if State.RevealMurderer and State.MurdererPlayer then
        LabelMurderer.Text = "☠ Assassino: " .. State.MurdererPlayer.Name
    else
        LabelMurderer.Text = "Assassino: Oculto"
    end

    if State.RevealSheriff and State.SheriffPlayer then
        LabelSheriff.Text = "✦ Xerife: " .. State.SheriffPlayer.Name
    else
        LabelSheriff.Text = "Xerife: Oculto"
    end
end)

-- ═══════════════════════════════
--   ABAS DO MENU LATERAL
-- ═══════════════════════════════
local Abas = {}
local Paginas = {}
local AbaAtiva = nil

local listaAbas = {
    {nome = "Home",          icone = "🏠"},
    {nome = "Visual",        icone = "👁"},
    {nome = "Jogadores",     icone = "👤"},
    {nome = "Rodada",        icone = "🔄"},
    {nome = "Itens",         icone = "💎"},
    {nome = "Mira",          icone = "🎯"},
    {nome = "Configurações", icone = "⚙"},
}

local function MudarAba(nome)
    for _, aba in pairs(Abas) do
        local ativo = aba.Name == nome
        aba.BackgroundColor3 = ativo and Color3.fromRGB(180, 40, 60) or Color3.fromRGB(0,0,0,0)
        aba.BackgroundTransparency = ativo and 0 or 1
        aba.TextColor3 = ativo and Color3.fromRGB(255,255,255) or Color3.fromRGB(150,150,170)
    end
    for _, pag in pairs(Paginas) do
        pag.Visible = pag.Name == nome
    end
    AbaAtiva = nome
end

for i, info in ipairs(listaAbas) do
    local btn = Instance.new("TextButton")
    btn.Name = info.nome
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundTransparency = 1
    btn.Text = "  " .. info.icone .. "  " .. info.nome
    btn.TextColor3 = Color3.fromRGB(150, 150, 170)
    btn.TextSize = 13
    btn.Font = Enum.Font.Gotham
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.LayoutOrder = i
    btn.Parent = Sidebar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)

    btn.MouseButton1Click:Connect(function() MudarAba(info.nome) end)
    table.insert(Abas, btn)

    local pag = CriarPagina(info.nome)
    table.insert(Paginas, pag)
end

-- ═══════════════════════════════
--      CONTEÚDO DAS PÁGINAS
-- ═══════════════════════════════

-- ── HOME ──
local pageHome = Conteudo:FindFirstChild("Home")
CriarSecao(pageHome, "Painel de controle")

local statusLabel = Instance.new("Frame")
statusLabel.Size = UDim2.new(1, 0, 0, 80)
statusLabel.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
statusLabel.BorderSizePixel = 0
statusLabel.LayoutOrder = 2
statusLabel.Parent = pageHome
Instance.new("UICorner", statusLabel).CornerRadius = UDim.new(0, 7)

local welcomeText = Instance.new("TextLabel")
welcomeText.Size = UDim2.new(1, -16, 1, 0)
welcomeText.Position = UDim2.new(0, 8, 0, 0)
welcomeText.Text = "Bem-vindo, " .. LocalPlayer.Name .. "!\n\nExu Menu v1.0 — MM2 Script OP\nUse as abas ao lado para configurar."
welcomeText.TextColor3 = Color3.fromRGB(190, 190, 210)
welcomeText.TextSize = 12
welcomeText.Font = Enum.Font.Gotham
welcomeText.BackgroundTransparency = 1
welcomeText.TextXAlignment = Enum.TextXAlignment.Left
welcomeText.TextYAlignment = Enum.TextYAlignment.Top
welcomeText.TextWrapped = true
welcomeText.Parent = statusLabel

CriarSecao(pageHome, "Ações rápidas")
CriarBotao(pageHome, "Abrir Visual", function() MudarAba("Visual") end, 4)
CriarBotao(pageHome, "Abrir Jogadores", function() MudarAba("Jogadores") end, 5)
CriarBotao(pageHome, "Abrir Mira", function() MudarAba("Mira") end, 6)

-- ── VISUAL ──
local pageVisual = Conteudo:FindFirstChild("Visual")
CriarSecao(pageVisual, "ESP — Visualização")

CriarToggle(pageVisual, "ESP Habilitado", false, function(v)
    State.ESP_Habilitado = v
end, 2)
CriarToggle(pageVisual, "Mostrar Caixas", true, function(v)
    State.ESP_Caixas = v
end, 3)
CriarToggle(pageVisual, "Mostrar Nomes", true, function(v)
    State.ESP_Nomes = v
end, 4)
CriarToggle(pageVisual, "Mostrar Função (Assassino/Xerife)", true, function(v)
    State.ESP_Funcoes = v
end, 5)
CriarToggle(pageVisual, "Mostrar Distância", true, function(v)
    State.ESP_Distancia = v
end, 6)
CriarToggle(pageVisual, "Tracers (linha até jogador)", false, function(v)
    State.ESP_Tracers = v
end, 7)
CriarToggle(pageVisual, "Destaque Assassino (vermelho)", true, function(v)
    State.DestaqueMurderer = v
end, 8)
CriarToggle(pageVisual, "Destaque Xerife (azul)", true, function(v)
    State.DestaqueSheriff = v
end, 9)

-- ── JOGADORES ──
local pageJog = Conteudo:FindFirstChild("Jogadores")
CriarSecao(pageJog, "Movimento")

CriarToggle(pageJog, "Speed Hack", false, function(v)
    State.SpeedHack = v
    AtualizarSpeed()
end, 2)
CriarSlider(pageJog, "Velocidade", 16, 200, 32, function(v)
    State.VelocidadeValor = v
    if State.SpeedHack then AtualizarSpeed() end
end, 3)
CriarToggle(pageJog, "NoClip (atravessar paredes)", false, function(v)
    State.NoClip = v
end, 4)
CriarToggle(pageJog, "Pulo Infinito", false, function(v)
    State.InfiniteJump = v
end, 5)
CriarToggle(pageJog, "Anti Morte (God Mode)", false, function(v)
    State.AntiMorte = v
end, 6)

CriarSecao(pageJog, "Teleporte")
local _, inputTpJog = CriarInput(pageJog, "Nome do jogador...", function(v)
    State.TeleportJogador = v
end, 8)
CriarBotao(pageJog, "Teleportar para Jogador", function()
    if State.TeleportJogador ~= "" then
        local ok = TeleportarPara(State.TeleportJogador)
        if not ok then
            -- silencioso
        end
    end
end, 9)

-- ── RODADA ──
local pageRodada = Conteudo:FindFirstChild("Rodada")
CriarSecao(pageRodada, "Informações da Rodada")

CriarToggle(pageRodada, "Revelar Assassino", false, function(v)
    State.RevealMurderer = v
end, 2)
CriarToggle(pageRodada, "Revelar Xerife", false, function(v)
    State.RevealSheriff = v
end, 3)
CriarToggle(pageRodada, "Auto Coletar Moedas", false, function(v)
    State.AutoColetarMoedas = v
end, 4)

-- ── ITENS ──
local pageItens = Conteudo:FindFirstChild("Itens")
CriarSecao(pageItens, "Itens do Mapa")

CriarToggle(pageItens, "ESP de Itens no Chão", false, function(v)
    State.ItemESP = v
end, 2)
CriarToggle(pageItens, "Auto Coletar Itens", false, function(v)
    State.AutoColetarItens = v
end, 3)

-- Item ESP loop
RunService.RenderStepped:Connect(function()
    -- limpar drawings de itens seria complexo, feito via highlights
    if State.ItemESP then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("MeshPart") then
                local nome = obj.Name:lower()
                if nome:find("coin") or nome:find("moeda") or nome:find("gun") or nome:find("knife") then
                    if not obj:FindFirstChildOfClass("SelectionBox") then
                        local sb = Instance.new("SelectionBox")
                        sb.Adornee = obj
                        sb.Color3 = Color3.fromRGB(255, 220, 0)
                        sb.LineThickness = 0.04
                        sb.SurfaceTransparency = 0.7
                        sb.SurfaceColor3 = Color3.fromRGB(255, 220, 0)
                        sb.Parent = obj
                    end
                end
            end
        end
    else
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local sb = obj:FindFirstChildOfClass("SelectionBox")
            if sb then sb:Destroy() end
        end
    end
end)

-- Auto coletar itens loop
RunService.Heartbeat:Connect(function()
    if State.AutoColetarItens then
        local meuraiz = ObterRaiz(LocalPlayer)
        if not meuraiz then return end
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local nome = obj.Name:lower()
                if nome:find("coin") or nome:find("moeda") or nome:find("gun") then
                    local d = (obj.Position - meuraiz.Position).Magnitude
                    if d < 60 then
                        meuraiz.CFrame = CFrame.new(obj.Position + Vector3.new(0, 3, 0))
                    end
                end
            end
        end
    end
end)

-- ── MIRA ──
local pageMira = Conteudo:FindFirstChild("Mira")
CriarSecao(pageMira, "Aimbot")

CriarToggle(pageMira, "Aimbot (Segurar MB2)", false, function(v)
    State.Aimbot = v
end, 2)
CriarToggle(pageMira, "Silent Aim (bala vai direto)", false, function(v)
    State.SilentAim = v
end, 3)
CriarSlider(pageMira, "FOV do Aimbot", 10, 500, 150, function(v)
    State.AimbotFOV = v
end, 4)
CriarSlider(pageMira, "Suavidade (menor = mais rápido)", 1, 100, 15, function(v)
    State.AimbotSmooth = v / 100
end, 5)

CriarSecao(pageMira, "Osso Alvo")
local ossoBtns = {"Head", "HumanoidRootPart", "Torso"}
for i, osso in ipairs(ossoBtns) do
    local nomesPT = {Head = "Cabeça", HumanoidRootPart = "Corpo (Centro)", Torso = "Tronco"}
    CriarBotao(pageMira, (State.AimbotOsso == osso and "✓ " or "") .. nomesPT[osso], function()
        State.AimbotOsso = osso
    end, 6 + i)
end

-- ── CONFIGURAÇÕES ──
local pageConfig = Conteudo:FindFirstChild("Configurações")
CriarSecao(pageConfig, "Interface")

CriarToggle(pageConfig, "Mostrar Info de Rodada (painel lateral)", true, function(v)
    InfoPanel.Visible = v
end, 2)

CriarSecao(pageConfig, "Sistema")
CriarBotao(pageConfig, "Desativar Todo o ESP", function()
    State.ESP_Habilitado = false
end, 4)
CriarBotao(pageConfig, "Restaurar Velocidade", function()
    State.SpeedHack = false
    local hum = ObterHumanoid(LocalPlayer)
    if hum then hum.WalkSpeed = 16 end
end, 5)
CriarBotao(pageConfig, "Restaurar NoClip OFF", function()
    State.NoClip = false
end, 6)

-- ═══════════════════════════════
--   DRAGGABLE (arrastar janela)
-- ═══════════════════════════════
local dragging = false
local dragStart, startPos

Header.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = inp.Position
        startPos = Janela.Position
    end
end)

UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(inp)
    if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = inp.Position - dragStart
        Janela.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- ═══════════════════════════════
--   FECHAR / MINIMIZAR / TOGGLE
-- ═══════════════════════════════
BtnFechar.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    -- limpar ESP drawings
    for plr, obj in pairs(State.ESPObjects) do
        for _, v in pairs(obj) do
            if v and v.Remove then pcall(function() v:Remove() end) end
        end
    end
    FOVCircle:Remove()
end)

local minimizado = false
BtnMin.MouseButton1Click:Connect(function()
    minimizado = not minimizado
    Conteudo.Visible = not minimizado
    Sidebar.Visible = not minimizado
    Sep.Visible = not minimizado
    Janela.Size = minimizado and UDim2.new(0, 680, 0, 52) or UDim2.new(0, 680, 0, 480)
end)

-- Toggle com INSERT
UserInputService.InputBegan:Connect(function(inp)
    if inp.KeyCode == Enum.KeyCode.Insert then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
end)

-- ═══════════════════════════════
--      LOOP PRINCIPAL ESP
-- ═══════════════════════════════
RunService.RenderStepped:Connect(AtualizarESP)

Players.PlayerAdded:Connect(function(plr)
    task.wait(1)
    CriarESPJogador(plr)
end)
Players.PlayerRemoving:Connect(function(plr)
    RemoverESPJogador(plr)
end)

-- Inicializar
MudarAba("Home")

print("[Exu Menu] Carregado com sucesso! INSERT para mostrar/ocultar.")
