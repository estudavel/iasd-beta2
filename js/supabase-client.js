/* ============================================================
   SUPABASE CLIENT - PROJETO IASD EXTENSÃO
   Configuração centralizada do cliente Supabase
   ============================================================ */

// CONFIGURAÇÃO - SUBSTITUA COM SUAS CREDENCIAIS DO SUPABASE
const SUPABASE_URL = 'https://ljmatrsblwbglvasnflb.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxqbWF0cnNibHdiZ2x2YXNuZmxiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU0MTAzNzIsImV4cCI6MjA5MDk4NjM3Mn0.KQ-yHpodAv55T8iY6GTJlUJM8tT66fa5HHmjXJd0A9w';

// Inicializar cliente Supabase
let supabaseClient;
    
try {
    supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
        auth: {
            autoRefreshToken: true,
            persistSession: true,
            detectSessionInUrl: true
        }
    });
    console.log('✅ Supabase inicializado com sucesso');
} catch (error) {
    console.error('❌ Erro ao inicializar Supabase:', error);
    showNotification('Erro de conexão com o servidor. Tente novamente mais tarde.', 'error');
}

/* ============================================================
   FUNÇÕES DE AUTENTICAÇÃO
   ============================================================ */

/**
 * Registra um novo usuário
 * @param {string} email - Email do usuário
 * @param {string} password - Senha do usuário
 * @param {object} userData - Dados adicionais do perfil
 */
async function signUp(email, password, userData) {
    try {
        // 1. Criar usuário na autenticação
        const { data: authData, error: authError } = await supabaseClient.auth.signUp({
            email,
            password,
        });

        if (authError) throw authError;

        // 2. Criar perfil na tabela perfis
        if (authData.user) {
            const { error: profileError } = await supabaseClient
                .from('perfis')
                .insert([{
                    id: authData.user.id,
                    email: email,
                    nome_completo: userData.nomeCompleto,
                    telefone: userData.telefone,
                    data_nascimento: userData.dataNascimento,
                    tipo_usuario: 'membro',
                    endereco: userData.endereco,
                    cidade: userData.cidade,
                    cep: userData.cep
                }]);

            if (profileError) throw profileError;
        }

        return { success: true, data: authData };
    } catch (error) {
        console.error('Erro no cadastro:', error);
        return { success: false, error: error.message };
    }
}

/**
 * Login do usuário
 * @param {string} email - Email do usuário
 * @param {string} password - Senha do usuário
 */
async function signIn(email, password) {
    try {
        const { data, error } = await supabaseClient.auth.signInWithPassword({
            email,
            password
        });

        if (error) throw error;

        return { success: true, data };
    } catch (error) {
        console.error('Erro no login:', error);
        return { success: false, error: error.message };
    }
}

/**
 * Logout do usuário
 */
async function signOut() {
    try {
        const { error } = await supabaseClient.auth.signOut();
        if (error) throw error;
        
        window.location.href = 'index.html';
    } catch (error) {
        console.error('Erro no logout:', error);
        showNotification('Erro ao sair. Tente novamente.', 'error');
    }
}

/**
 * Obtém o usuário atual
 */
async function getCurrentUser() {
    try {
        // usar getsession em vez de getuser evita o erro vermelho no console para visitantes
        const { data: { session }, error } = await supabaseClient.auth.getSession();
        if (error) throw error;
        return session ? session.user : null;
    } catch (error) {
        return null;
    }
}

/**
 * Obtém o perfil completo do usuário logado
 */
async function getCurrentProfile() {
    try {
        const user = await getCurrentUser();
        if (!user) return null;

        const { data, error } = await supabaseClient
            .from('perfis')
            .select('*')
            .eq('id', user.id)
            .single();

        if (error) throw error;
        return data;
    } catch (error) {
        console.error('Erro ao obter perfil:', error);
        return null;
    }
}

/**
 * Verifica se o usuário é líder ou admin
 */
async function isLeaderOrAdmin() {
    const profile = await getCurrentProfile();
    return profile && (profile.tipo_usuario === 'lider' || profile.tipo_usuario === 'admin');
}

/* ============================================================
   FUNÇÕES DE VOLUNTARIADO
   ============================================================ */

/**
 * Cadastra um novo voluntário
 * @param {object} voluntarioData - Dados do voluntário
 */
async function cadastrarVoluntario(voluntarioData) {
    try {
        const user = await getCurrentUser();
        if (!user) throw new Error('Usuário não autenticado');

        const { data, error } = await supabaseClient
            .from('voluntarios')
            .insert([{
                perfil_id: user.id,
                area_id: voluntarioData.areaId,
                eh_estudante_enfermagem: voluntarioData.ehEstudanteEnfermagem,
                instituicao_ensino: voluntarioData.instituicaoEnsino,
                matricula: voluntarioData.matricula,
                periodo_atual: voluntarioData.periodoAtual,
                registro_coren: voluntarioData.registroCoren,
                dias_disponiveis: voluntarioData.diasDisponiveis,
                turno_preferido: voluntarioData.turnoPreferido,
                observacoes: voluntarioData.observacoes
            }]);

        if (error) throw error;
        return { success: true, data };
    } catch (error) {
        console.error('Erro ao cadastrar voluntário:', error);
        return { success: false, error: error.message };
    }
}

/**
 * Solicita acompanhamento de saúde para idoso
 * @param {object} idosoData - Dados do idoso
 */
async function solicitarAcompanhamentoIdoso(idosoData) {
    try {
        const user = await getCurrentUser();
        if (!user) throw new Error('Usuário não autenticado');

        const { data, error } = await supabaseClient
            .from('idosos_acompanhamento')
            .insert([{
                perfil_id: user.id,
                nome_responsavel: idosoData.nomeResponsavel,
                telefone_responsavel: idosoData.telefoneResponsavel,
                condicoes_medicas: idosoData.condicoesMedicas,
                medicamentos: idosoData.medicamentos,
                alergias: idosoData.alergias,
                necessita_pressao: idosoData.necessitaPressao,
                necessita_glicemia: idosoData.necessitaGlicemia,
                necessita_outros: idosoData.necessitaOutros,
                outros_servicos: idosoData.outrosServicos,
                endereco_completo: idosoData.enderecoCompleto,
                ponto_referencia: idosoData.pontoReferencia
            }]);

        if (error) throw error;
        return { success: true, data };
    } catch (error) {
        console.error('Erro ao solicitar acompanhamento:', error);
        return { success: false, error: error.message };
    }
}

/**
 * Obtém lista de áreas de voluntariado
 */
async function getAreasVoluntariado() {
    try {
        const { data, error } = await supabaseClient
            .from('areas_voluntariado')
            .select('*')
            .eq('ativo', true)
            .order('nome');

        if (error) throw error;
        return { success: true, data };
    } catch (error) {
        console.error('Erro ao buscar áreas:', error);
        return { success: false, error: error.message };
    }
}

/* ============================================================
   FUNÇÕES DE AGENDAMENTO DE ESTUDOS
   ============================================================ */

/**
 * Agenda um estudo bíblico
 * @param {object} agendamentoData - Dados do agendamento
 */
/**
 * agenda um estudo bíblico (suporta usuários anônimos e logados)
 */
async function agendarEstudo(agendamentoData) {
    try {
        const user = await getCurrentUser();
        
        // monta o pacote de dados para enviar ao banco
        const insertData = {
            data_preferida: agendamentoData.dataPreferida,
            horario_preferido: agendamentoData.horarioPreferido,
            modalidade: agendamentoData.modalidade,
            endereco_presencial: agendamentoData.enderecoPresencial,
            link_online: agendamentoData.linkOnline,
            tema_interesse: agendamentoData.temaInteresse,
            observacoes: agendamentoData.observacoes,
            nome_solicitante: agendamentoData.nome,
            email_solicitante: agendamentoData.email,
            telefone_solicitante: agendamentoData.telefone
        };

        // se a pessoa estiver logada, vincula o agendamento à conta dela
        if (user) {
            insertData.solicitante_id = user.id;
        }

        const { data, error } = await supabaseClient
            .from('agendamentos_estudos')
            .insert([insertData]);

        if (error) throw error;
        return { success: true, data };
    } catch (error) {
        console.error('erro ao agendar estudo:', error);
        return { success: false, error: error.message };
    }
}

/**
 * Obtém agendamentos do usuário
 */
async function getMeusAgendamentos() {
    try {
        const user = await getCurrentUser();
        if (!user) throw new Error('Usuário não autenticado');

        const { data, error } = await supabaseClient
            .from('agendamentos_estudos')
            .select('*')
            .eq('solicitante_id', user.id)
            .order('data_preferida', { ascending: true });

        if (error) throw error;
        return { success: true, data };
    } catch (error) {
        console.error('Erro ao buscar agendamentos:', error);
        return { success: false, error: error.message };
    }
}

/* ============================================================
   FUNÇÕES DO MURAL DE ORAÇÕES
   ============================================================ */

/**
 * Envia um pedido de oração
 * @param {object} oracaoData - Dados do pedido
 */
async function enviarPedidoOracao(oracaoData) {
    try {
        const user = await getCurrentUser();
        
        const insertData = {
            titulo: oracaoData.titulo,
            conteudo: oracaoData.conteudo,
            categoria: oracaoData.categoria,
            nivel_privacidade: oracaoData.nivelPrivacidade,
            status: 'ativo'
        };

        // Se não for anônimo e usuário estiver logado
        if (oracaoData.nivelPrivacidade !== 'anonimo' && user) {
            insertData.solicitante_id = user.id;
        }

        // Se for anônimo, definir nome de exibição
        if (oracaoData.nivelPrivacidade === 'anonimo') {
            insertData.nome_exibicao = 'Irmão/Irmã anônimo(a)';
        }

        const { data, error } = await supabaseClient
            .from('pedidos_oracao')
            .insert([insertData]);

        if (error) throw error;
        return { success: true, data };
    } catch (error) {
        console.error('Erro ao enviar pedido:', error);
        return { success: false, error: error.message };
    }
}

/**
 * Obtém pedidos de oração públicos (visível para todos)
 */
async function getPedidosOracaoPublicos() {
    try {
        const { data, error } = await supabaseClient
            .from('pedidos_oracao')
            .select(`
                *,
                perfis:solicitante_id (nome_completo)
            `)
            .in('nivel_privacidade', ['publico', 'anonimo'])
            .eq('status', 'ativo')
            .order('created_at', { ascending: false })
            .limit(20);

        if (error) throw error;
        return { success: true, data };
    } catch (error) {
        console.error('Erro ao buscar pedidos:', error);
        return { success: false, error: error.message };
    }
}

/**
 * Registra que o usuário está orando por um pedido
 * @param {string} pedidoId - ID do pedido
 */
async function registrarOracao(pedidoId) {
    try {
        const user = await getCurrentUser();
        if (!user) throw new Error('Faça login para registrar sua oração');

        const { data, error } = await supabaseClient
            .from('oracoes_pedido')
            .insert([{
                pedido_id: pedidoId,
                perfil_id: user.id
            }]);

        if (error) throw error;
        return { success: true, data };
    } catch (error) {
        console.error('Erro ao registrar oração:', error);
        return { success: false, error: error.message };
    }
}

/* ============================================================
   FUNÇÕES DE CONTATO
   ============================================================ */

/**
 * Envia mensagem de contato
 * @param {object} mensagemData - Dados da mensagem
 */
async function enviarMensagemContato(mensagemData) {
    try {
        const { data, error } = await supabaseClient
            .from('mensagens_contato')
            .insert([{
                nome: mensagemData.nome,
                email: mensagemData.email,
                telefone: mensagemData.telefone,
                assunto: mensagemData.assunto,
                mensagem: mensagemData.mensagem,
                departamento_destino: mensagemData.departamento || 'geral'
            }]);

        if (error) throw error;
        return { success: true, data };
    } catch (error) {
        console.error('Erro ao enviar mensagem:', error);
        return { success: false, error: error.message };
    }
}

/**
 * Obtém lista de líderes (público)
 */
async function getLideres() {
    try {
        const { data, error } = await supabaseClient
            .from('lideres')
            .select('*')
            .eq('exibir_contato', true)
            .order('ordem_exibicao');

        if (error) throw error;
        return { success: true, data };
    } catch (error) {
        console.error('Erro ao buscar líderes:', error);
        return { success: false, error: error.message };
    }
}

/* ============================================================
   FUNÇÕES UTILITÁRIAS
   ============================================================ */

/**
 * Formata data para exibição
 * @param {string} dateString - Data em formato ISO
 */
function formatarData(dateString) {
    if (!dateString) return '';
    const data = new Date(dateString);
    return data.toLocaleDateString('pt-BR', {
        day: '2-digit',
        month: 'long',
        year: 'numeric'
    });
}

/**
 * Formata data e hora para exibição
 * @param {string} dateString - Data em formato ISO
 * @param {string} timeString - Hora em formato HH:MM
 */
function formatarDataHora(dateString, timeString) {
    const data = formatarData(dateString);
    if (!timeString) return data;
    return `${data} às ${timeString}`;
}

/**
 * Trunca texto com reticências
 * @param {string} text - Texto a truncar
 * @param {number} maxLength - Comprimento máximo
 */
function truncarTexto(text, maxLength = 100) {
    if (!text || text.length <= maxLength) return text;
    return text.substring(0, maxLength).trim() + '...';
}

/**
 * Mostra notificação na tela
 * @param {string} message - Mensagem
 * @param {string} type - Tipo: success, error, warning, info
 */
function showNotification(message, type = 'info') {
    // Remover notificações anteriores
    const existing = document.querySelector('.notification');
    if (existing) existing.remove();

    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.innerHTML = `
        <span class="notification-icon">${getIconForType(type)}</span>
        <span class="notification-message">${message}</span>
        <button class="notification-close" onclick="this.parentElement.remove()">&times;</button>
    `;

    document.body.appendChild(notification);

    // Auto-remover após 5 segundos
    setTimeout(() => {
        if (notification.parentElement) {
            notification.remove();
        }
    }, 5000);
}

function getIconForType(type) {
    const icons = {
        success: '✓',
        error: '✕',
        warning: '⚠',
        info: 'ℹ'
    };
    return icons[type] || icons.info;
}

/**
 * Valida email
 * @param {string} email - Email a validar
 */
function isValidEmail(email) {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email);
}

/**
 * Valida telefone brasileiro
 * @param {string} telefone - Telefone a validar
 */
function isValidTelefone(telefone) {
    const re = /^\(?[1-9]{2}\)? ?(?:[2-8]|9[1-9])[0-9]{3}-?[0-9]{4}$/;
    return re.test(telefone.replace(/\s/g, ''));
}

/**
 * Máscara para telefone
 * @param {string} value - Valor do input
 */
function maskTelefone(value) {
    return value
        .replace(/\D/g, '')
        .replace(/(\d{2})(\d)/, '($1) $2')
        .replace(/(\d{5})(\d)/, '$1-$2')
        .replace(/(-\d{4})\d+?$/, '$1');
}

/**
 * Máscara para CEP
 * @param {string} value - Valor do input
 */
function maskCEP(value) {
    return value
        .replace(/\D/g, '')
        .replace(/(\d{5})(\d)/, '$1-$2')
        .replace(/(-\d{3})\d+?$/, '$1');
}

/* ============================================================
   INICIALIZAÇÃO
   ============================================================ */

// Verificar sessão ao carregar a página
document.addEventListener('DOMContentLoaded', async () => {
    const user = await getCurrentUser();
    
    // Atualizar UI baseado no estado de autenticação
    updateAuthUI(user);
});

/**
 * Atualiza elementos da UI baseado no estado de autenticação
 * @param {object} user - Usuário atual ou null
 */
function updateAuthUI(user) {
    const authElements = document.querySelectorAll('[data-auth]');
    
    authElements.forEach(el => {
        const authState = el.dataset.auth;
        
        if (authState === 'authenticated' && user) {
            el.style.display = '';
        } else if (authState === 'anonymous' && !user) {
            el.style.display = '';
        } else {
            el.style.display = 'none';
        }
    });

    // Atualizar nome do usuário se existir
    if (user) {
        const userNameElements = document.querySelectorAll('[data-user-name]');
        userNameElements.forEach(el => {
            el.textContent = user.email;
        });
    }
}
