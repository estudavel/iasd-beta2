-- ============================================================
-- SCHEMA SUPABASE - PROJETO IASD EXTENSÃO UNIVERSITÁRIA
-- Sistemas de Informação e Sociedade
-- ============================================================
-- Este schema implementa o princípio de Exposição Mínima de Dados
-- Apenas usuários autorizados podem acessar dados sensíveis
-- ============================================================

-- ============================================================
-- 1. TABELAS DE PERFIS E AUTENTICAÇÃO
-- ============================================================

-- Tabela de perfis de usuários (estende a auth.users do Supabase)
CREATE TABLE IF NOT EXISTS public.perfis (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nome_completo VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    telefone VARCHAR(20),
    data_nascimento DATE,
    tipo_usuario VARCHAR(50) NOT NULL DEFAULT 'membro' CHECK (tipo_usuario IN ('membro', 'voluntario', 'lider', 'admin', 'enfermagem')),
    endereco TEXT,
    cidade VARCHAR(100),
    cep VARCHAR(10),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de líderes da igreja (informações públicas)
CREATE TABLE IF NOT EXISTS public.lideres (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    perfil_id UUID REFERENCES public.perfis(id) ON DELETE SET NULL,
    nome VARCHAR(255) NOT NULL,
    cargo VARCHAR(100) NOT NULL,
    descricao TEXT,
    foto_url TEXT,
    email_publico VARCHAR(255),
    telefone_publico VARCHAR(20),
    exibir_contato BOOLEAN DEFAULT true,
    ordem_exibicao INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- 2. TABELAS DE VOLUNTARIADO E SAÚDE
-- ============================================================

-- Tabela de áreas de voluntariado
CREATE TABLE IF NOT EXISTS public.areas_voluntariado (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome VARCHAR(100) NOT NULL UNIQUE,
    descricao TEXT,
    icone VARCHAR(50),
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de voluntários (cadastro de estudantes e membros)
CREATE TABLE IF NOT EXISTS public.voluntarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    perfil_id UUID REFERENCES public.perfis(id) ON DELETE CASCADE,
    area_id UUID REFERENCES public.areas_voluntariado(id),
    
    -- Dados específicos para área de saúde/enfermagem
    eh_estudante_enfermagem BOOLEAN DEFAULT false,
    instituicao_ensino VARCHAR(255),
    matricula VARCHAR(50),
    periodo_atual INTEGER,
    registro_coren VARCHAR(50),
    
    -- Disponibilidade
    dias_disponiveis TEXT[], -- ['segunda', 'quarta', 'sexta']
    turno_preferido VARCHAR(20) CHECK (turno_preferido IN ('manha', 'tarde', 'noite', 'flexivel')),
    
    -- Status
    status VARCHAR(20) DEFAULT 'pendente' CHECK (status IN ('pendente', 'aprovado', 'rejeitado', 'inativo')),
    observacoes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de idosos que solicitam acompanhamento de saúde
CREATE TABLE IF NOT EXISTS public.idosos_acompanhamento (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    perfil_id UUID REFERENCES public.perfis(id) ON DELETE CASCADE,
    
    -- Dados de saúde (SENSÍVEIS - apenas líderes e voluntários de saúde)
    nome_responsavel VARCHAR(255),
    telefone_responsavel VARCHAR(20),
    condicoes_medicas TEXT[], -- ['hipertensao', 'diabetes', 'etc']
    medicamentos TEXT,
    alergias TEXT,
    
    -- Necessidades de acompanhamento
    necessita_pressao BOOLEAN DEFAULT false,
    necessita_glicemia BOOLEAN DEFAULT false,
    necessita_outros BOOLEAN DEFAULT false,
    outros_servicos TEXT,
    
    -- Endereço (SENSÍVEL)
    endereco_completo TEXT NOT NULL,
    ponto_referencia TEXT,
    
    -- Status
    status VARCHAR(20) DEFAULT 'ativo' CHECK (status IN ('ativo', 'pausado', 'concluido')),
    observacoes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de visitas/voluntariado realizadas
CREATE TABLE IF NOT EXISTS public.visitas_voluntariado (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    voluntario_id UUID REFERENCES public.voluntarios(id) ON DELETE CASCADE,
    idoso_id UUID REFERENCES public.idosos_acompanhamento(id) ON DELETE CASCADE,
    
    -- Dados da visita
    data_visita DATE NOT NULL,
    hora_inicio TIME,
    hora_fim TIME,
    
    -- Dados de saúde coletados (SENSÍVEIS)
    pressao_sistolica INTEGER,
    pressao_diastolica INTEGER,
    glicemia INTEGER,
    batimentos_cardiacos INTEGER,
    
    -- Observações
    observacoes_saude TEXT,
    observacoes_gerais TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- 3. TABELAS DE AGENDAMENTO DE ESTUDOS BÍBLICOS
-- ============================================================

-- Tabela de agendamentos de estudos bíblicos
CREATE TABLE IF NOT EXISTS public.agendamentos_estudos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    solicitante_id UUID REFERENCES public.perfis(id) ON DELETE CASCADE,
    
    -- Dados do agendamento
    data_preferida DATE NOT NULL,
    horario_preferido TIME NOT NULL,
    modalidade VARCHAR(20) NOT NULL CHECK (modalidade IN ('presencial', 'online')),
    
    -- Dados sensíveis (apenas líderes veem)
    endereco_presencial TEXT,
    link_online TEXT,
    
    -- Informações do estudo
    tema_interesse VARCHAR(100),
    observacoes TEXT,
    
    -- Status
    status VARCHAR(20) DEFAULT 'pendente' CHECK (status IN ('pendente', 'confirmado', 'cancelado', 'concluido')),
    lider_designado UUID REFERENCES public.perfis(id),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- 4. TABELAS DO MURAL DE ORAÇÕES
-- ============================================================

-- Tabela de pedidos de oração
CREATE TABLE IF NOT EXISTS public.pedidos_oracao (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    solicitante_id UUID REFERENCES public.perfis(id) ON DELETE SET NULL,
    
    -- Conteúdo do pedido
    titulo VARCHAR(200) NOT NULL,
    conteudo TEXT NOT NULL,
    categoria VARCHAR(50) DEFAULT 'geral' CHECK (categoria IN ('geral', 'saude', 'familia', 'trabalho', 'financeiro', 'espiritual', 'outros')),
    
    -- Nível de privacidade (REGRA CRÍTICA)
    nivel_privacidade VARCHAR(20) NOT NULL CHECK (nivel_privacidade IN ('publico', 'lideres', 'anonimo')),
    
    -- Se anônimo, ocultar completamente o autor
    nome_exibicao VARCHAR(100), -- Para anonimo: "Irmão/irmã anônimo"
    
    -- Status
    status VARCHAR(20) DEFAULT 'ativo' CHECK (status IN ('ativo', 'respondido', 'arquivado')),
    data_resposta DATE,
    resposta TEXT,
    
    -- Contador de orações (apenas para públicos)
    contador_oracoes INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de "estou orando" (interação com pedidos públicos)
CREATE TABLE IF NOT EXISTS public.oracoes_pedido (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_id UUID REFERENCES public.pedidos_oracao(id) ON DELETE CASCADE,
    perfil_id UUID REFERENCES public.perfis(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(pedido_id, perfil_id) -- Evita duplicatas
);

-- ============================================================
-- 5. TABELAS DE CONTATO E MENSAGENS
-- ============================================================

-- Tabela de mensagens de contato
CREATE TABLE IF NOT EXISTS public.mensagens_contato (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Dados do remetente
    nome VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    telefone VARCHAR(20),
    
    -- Conteúdo
    assunto VARCHAR(200) NOT NULL,
    mensagem TEXT NOT NULL,
    
    -- Destino (qual líder/departamento)
    departamento_destino VARCHAR(100) DEFAULT 'geral',
    
    -- Status
    lida BOOLEAN DEFAULT false,
    respondida BOOLEAN DEFAULT false,
    data_resposta TIMESTAMP WITH TIME ZONE,
    resposta TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- 6. ROW LEVEL SECURITY (RLS) - POLÍTICAS DE PRIVACIDADE
-- ============================================================

-- Habilitar RLS em todas as tabelas
ALTER TABLE public.perfis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lideres ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.areas_voluntariado ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.voluntarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.idosos_acompanhamento ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.visitas_voluntariado ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agendamentos_estudos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedidos_oracao ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.oracoes_pedido ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mensagens_contato ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 6.1 POLÍTICAS PARA PERFIS
-- ============================================================

-- Política: Usuários podem ver apenas seu próprio perfil
CREATE POLICY "Usuários veem próprio perfil" ON public.perfis
    FOR SELECT USING (auth.uid() = id);

-- Política: Líderes e admins podem ver todos os perfis
CREATE POLICY "Líderes veem todos perfis" ON public.perfis
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.perfis p 
            WHERE p.id = auth.uid() AND p.tipo_usuario IN ('lider', 'admin')
        )
    );

-- Política: Usuários podem inserir apenas seu próprio perfil
CREATE POLICY "Usuários inserem próprio perfil" ON public.perfis
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Política: Usuários podem atualizar apenas seu próprio perfil
CREATE POLICY "Usuários atualizam próprio perfil" ON public.perfis
    FOR UPDATE USING (auth.uid() = id);

-- ============================================================
-- 6.2 POLÍTICAS PARA LÍDERES (INFORMAÇÃO PÚBLICA)
-- ============================================================

-- Política: Todos podem ver líderes
CREATE POLICY "Todos veem líderes" ON public.lideres
    FOR SELECT USING (true);

-- Política: Apenas admins podem gerenciar líderes
CREATE POLICY "Admins gerenciam líderes" ON public.lideres
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.perfis p 
            WHERE p.id = auth.uid() AND p.tipo_usuario = 'admin'
        )
    );

-- ============================================================
-- 6.3 POLÍTICAS PARA VOLUNTARIADO
-- ============================================================

-- Áreas de voluntariado: todos podem ver
CREATE POLICY "Todos veem áreas" ON public.areas_voluntariado
    FOR SELECT USING (true);

-- Voluntários: usuário vê o próprio, líderes veem todos
CREATE POLICY "Voluntário vê próprio cadastro" ON public.voluntarios
    FOR SELECT USING (auth.uid() = perfil_id);

CREATE POLICY "Líderes veem todos voluntários" ON public.voluntarios
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.perfis p 
            WHERE p.id = auth.uid() AND p.tipo_usuario IN ('lider', 'admin')
        )
    );

CREATE POLICY "Usuário insere próprio voluntariado" ON public.voluntarios
    FOR INSERT WITH CHECK (auth.uid() = perfil_id);

CREATE POLICY "Líderes aprovam voluntários" ON public.voluntarios
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.perfis p 
            WHERE p.id = auth.uid() AND p.tipo_usuario IN ('lider', 'admin')
        )
    );

-- ============================================================
-- 6.4 POLÍTICAS PARA IDOSOS ACOMPANHAMENTO (DADOS SENSÍVEIS)
-- ============================================================

-- Política: Usuário vê apenas seus próprios dados de idoso
CREATE POLICY "Usuário vê próprio acompanhamento" ON public.idosos_acompanhamento
    FOR SELECT USING (auth.uid() = perfil_id);

-- Política: Voluntários de saúde aprovados e líderes veem todos
CREATE POLICY "Voluntários saúde veem idosos" ON public.idosos_acompanhamento
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.perfis p
            JOIN public.voluntarios v ON v.perfil_id = p.id
            WHERE p.id = auth.uid() 
            AND v.status = 'aprovado'
            AND (v.area_id IN (SELECT id FROM public.areas_voluntariado WHERE nome ILIKE '%saúde%')
                 OR v.area_id IN (SELECT id FROM public.areas_voluntariado WHERE nome ILIKE '%enfermagem%'))
        )
        OR EXISTS (
            SELECT 1 FROM public.perfis p 
            WHERE p.id = auth.uid() AND p.tipo_usuario IN ('lider', 'admin')
        )
    );

CREATE POLICY "Usuário insere próprio acompanhamento" ON public.idosos_acompanhamento
    FOR INSERT WITH CHECK (auth.uid() = perfil_id);

CREATE POLICY "Voluntários atualizam visitas" ON public.idosos_acompanhamento
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.perfis p
            JOIN public.voluntarios v ON v.perfil_id = p.id
            WHERE p.id = auth.uid() 
            AND v.status = 'aprovado'
            AND (v.area_id IN (SELECT id FROM public.areas_voluntariado WHERE nome ILIKE '%saúde%')
                 OR v.area_id IN (SELECT id FROM public.areas_voluntariado WHERE nome ILIKE '%enfermagem%'))
        )
        OR EXISTS (
            SELECT 1 FROM public.perfis p 
            WHERE p.id = auth.uid() AND p.tipo_usuario IN ('lider', 'admin')
        )
    );

-- ============================================================
-- 6.5 POLÍTICAS PARA VISITAS (DADOS SENSÍVEIS)
-- ============================================================

CREATE POLICY "Voluntários veem próprias visitas" ON public.visitas_voluntariado
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.voluntarios v
            WHERE v.id = visitas_voluntariado.voluntario_id
            AND v.perfil_id = auth.uid()
        )
    );

CREATE POLICY "Líderes veem todas visitas" ON public.visitas_voluntariado
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.perfis p 
            WHERE p.id = auth.uid() AND p.tipo_usuario IN ('lider', 'admin')
        )
    );

CREATE POLICY "Voluntários registram visitas" ON public.visitas_voluntariado
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.voluntarios v
            WHERE v.id = voluntario_id
            AND v.perfil_id = auth.uid()
            AND v.status = 'aprovado'
        )
    );

-- ============================================================
-- 6.6 POLÍTICAS PARA AGENDAMENTOS
-- ============================================================

CREATE POLICY "Usuário vê próprios agendamentos" ON public.agendamentos_estudos
    FOR SELECT USING (auth.uid() = solicitante_id);

CREATE POLICY "Líderes veem todos agendamentos" ON public.agendamentos_estudos
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.perfis p 
            WHERE p.id = auth.uid() AND p.tipo_usuario IN ('lider', 'admin')
        )
    );

CREATE POLICY "Usuário cria agendamento" ON public.agendamentos_estudos
    FOR INSERT WITH CHECK (auth.uid() = solicitante_id);

CREATE POLICY "Líderes gerenciam agendamentos" ON public.agendamentos_estudos
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.perfis p 
            WHERE p.id = auth.uid() AND p.tipo_usuario IN ('lider', 'admin')
        )
    );

-- ============================================================
-- 6.7 POLÍTICAS PARA MURAL DE ORAÇÕES (REGRA CRÍTICA)
-- ============================================================

-- REGRA: Pedidos PÚBLICOS e ANÔNIMOS são visíveis para todos
-- Pedidos de LÍDERES são visíveis apenas para líderes

CREATE POLICY "Todos veem pedidos públicos e anônimos" ON public.pedidos_oracao
    FOR SELECT USING (
        nivel_privacidade IN ('publico', 'anonimo')
        AND status = 'ativo'
    );

CREATE POLICY "Líderes veem todos pedidos" ON public.pedidos_oracao
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.perfis p 
            WHERE p.id = auth.uid() AND p.tipo_usuario IN ('lider', 'admin')
        )
    );

CREATE POLICY "Usuário vê próprios pedidos privados" ON public.pedidos_oracao
    FOR SELECT USING (auth.uid() = solicitante_id);

CREATE POLICY "Usuário cria pedido" ON public.pedidos_oracao
    FOR INSERT WITH CHECK (auth.uid() = solicitante_id);

CREATE POLICY "Líderes respondem pedidos" ON public.pedidos_oracao
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.perfis p 
            WHERE p.id = auth.uid() AND p.tipo_usuario IN ('lider', 'admin')
        )
    );

-- ============================================================
-- 6.8 POLÍTICAS PARA ORAÇÕES_PEDIDO (INTERAÇÃO)
-- ============================================================

CREATE POLICY "Todos veem contadores" ON public.oracoes_pedido
    FOR SELECT USING (true);

CREATE POLICY "Usuários registram oração" ON public.oracoes_pedido
    FOR INSERT WITH CHECK (auth.uid() = perfil_id);

-- ============================================================
-- 6.9 POLÍTICAS PARA MENSAGENS DE CONTATO
-- ============================================================

-- Qualquer um pode enviar mensagem (anônimo)
CREATE POLICY "Qualquer um envia mensagem" ON public.mensagens_contato
    FOR INSERT WITH CHECK (true);

-- Apenas líderes veem mensagens
CREATE POLICY "Líderes veem mensagens" ON public.mensagens_contato
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.perfis p 
            WHERE p.id = auth.uid() AND p.tipo_usuario IN ('lider', 'admin')
        )
    );

CREATE POLICY "Líderes atualizam mensagens" ON public.mensagens_contato
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.perfis p 
            WHERE p.id = auth.uid() AND p.tipo_usuario IN ('lider', 'admin')
        )
    );

-- ============================================================
-- 7. FUNÇÕES E TRIGGERS
-- ============================================================

-- Função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION public.atualizar_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para atualizar updated_at
CREATE TRIGGER atualizar_perfis_updated_at
    BEFORE UPDATE ON public.perfis
    FOR EACH ROW EXECUTE FUNCTION public.atualizar_updated_at();

CREATE TRIGGER atualizar_voluntarios_updated_at
    BEFORE UPDATE ON public.voluntarios
    FOR EACH ROW EXECUTE FUNCTION public.atualizar_updated_at();

CREATE TRIGGER atualizar_idosos_updated_at
    BEFORE UPDATE ON public.idosos_acompanhamento
    FOR EACH ROW EXECUTE FUNCTION public.atualizar_updated_at();

CREATE TRIGGER atualizar_agendamentos_updated_at
    BEFORE UPDATE ON public.agendamentos_estudos
    FOR EACH ROW EXECUTE FUNCTION public.atualizar_updated_at();

CREATE TRIGGER atualizar_pedidos_oracao_updated_at
    BEFORE UPDATE ON public.pedidos_oracao
    FOR EACH ROW EXECUTE FUNCTION public.atualizar_updated_at();

-- Função para incrementar contador de orações
CREATE OR REPLACE FUNCTION public.incrementar_contador_oracoes()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.pedidos_oracao
    SET contador_oracoes = contador_oracoes + 1
    WHERE id = NEW.pedido_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_incrementar_oracoes
    AFTER INSERT ON public.oracoes_pedido
    FOR EACH ROW EXECUTE FUNCTION public.incrementar_contador_oracoes();

-- ============================================================
-- 8. DADOS INICIAIS
-- ============================================================

-- Inserir áreas de voluntariado padrão
INSERT INTO public.areas_voluntariado (nome, descricao, icone) VALUES
    ('Saúde/Enfermagem', 'Acompanhamento de saúde para idosos: pressão arterial, glicemia, cuidados básicos', 'heart-pulse'),
    ('Assistência Social', 'Visitas a membros necessitados, doações, apoio social', 'hands-holding-circle'),
    ('Ensino e Educação', 'Aulas de reforço escolar, alfabetização, cursos', 'book-open'),
    ('Música e Louvor', 'Participação no coral, grupo musical, instrumentistas', 'music'),
    ('Comunicação', 'Mídias sociais, fotografia, design, transmissões', 'camera'),
    ('Manutenção', 'Pequenos reparos, jardinagem, cuidados com o prédio', 'wrench'),
    ('Cozinha e Eventos', 'Preparação de alimentos, organização de eventos', 'utensils'),
    ('Recepção', 'Acolhimento de visitantes, orientação de membros', 'door-open')
ON CONFLICT (nome) DO NOTHING;

-- ============================================================
-- 9. ÍNDICES PARA PERFORMANCE
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_perfis_tipo ON public.perfis(tipo_usuario);
CREATE INDEX IF NOT EXISTS idx_voluntarios_status ON public.voluntarios(status);
CREATE INDEX IF NOT EXISTS idx_voluntarios_area ON public.voluntarios(area_id);
CREATE INDEX IF NOT EXISTS idx_idosos_status ON public.idosos_acompanhamento(status);
CREATE INDEX IF NOT EXISTS idx_agendamentos_status ON public.agendamentos_estudos(status);
CREATE INDEX IF NOT EXISTS idx_agendamentos_data ON public.agendamentos_estudos(data_preferida);
CREATE INDEX IF NOT EXISTS idx_pedidos_privacidade ON public.pedidos_oracao(nivel_privacidade);
CREATE INDEX IF NOT EXISTS idx_pedidos_status ON public.pedidos_oracao(status);
CREATE INDEX IF NOT EXISTS idx_mensagens_lida ON public.mensagens_contato(lida);

-- ============================================================
-- FIM DO SCHEMA
-- ============================================================
