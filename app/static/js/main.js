// PUP Parañaque Reservation System - Core JavaScript Helper

document.addEventListener('DOMContentLoaded', () => {
    // 0. Landing navbar active state
    const landingNavLinks = document.querySelectorAll('.landing-nav-link[data-landing-section]');
    const setLandingNavActive = (section) => {
        if (!landingNavLinks.length) return;
        landingNavLinks.forEach(link => {
            link.classList.toggle('active', link.dataset.landingSection === section);
        });
    };

    if (landingNavLinks.length) {
        const landingSections = ['about', 'facilities']
            .map(id => document.getElementById(id))
            .filter(Boolean);

        const updateLandingNavFromLocation = () => {
            const hashSection = window.location.hash.replace('#', '');
            if (hashSection && document.getElementById(hashSection)) {
                setLandingNavActive(hashSection);
                return;
            }
            setLandingNavActive('home');
        };

        updateLandingNavFromLocation();
        window.addEventListener('hashchange', updateLandingNavFromLocation);

        landingNavLinks.forEach(link => {
            link.addEventListener('click', () => {
                setLandingNavActive(link.dataset.landingSection || 'home');
            });
        });

        if (landingSections.length) {
            window.addEventListener('scroll', () => {
                let current = 'home';
                landingSections.forEach(section => {
                    const rect = section.getBoundingClientRect();
                    if (rect.top <= 120) {
                        current = section.id;
                    }
                });
                setLandingNavActive(current);
            }, { passive: true });
        }
    }

    // 0.5 Styled confirmation dialogs for destructive or final actions
    const confirmModalEl = document.getElementById('appConfirmModal');
    const confirmTitleEl = document.getElementById('appConfirmTitle');
    const confirmMessageEl = document.getElementById('appConfirmMessage');
    const confirmSubmitBtn = document.getElementById('appConfirmSubmit');
    let pendingConfirmForm = null;

    if (confirmModalEl && confirmSubmitBtn && typeof bootstrap !== 'undefined') {
        const confirmModal = new bootstrap.Modal(confirmModalEl);

        document.querySelectorAll('form[data-confirm-message]').forEach((form) => {
            form.addEventListener('submit', (event) => {
                if (form.dataset.confirmed === 'true') {
                    delete form.dataset.confirmed;
                    return;
                }

                event.preventDefault();
                pendingConfirmForm = form;
                confirmTitleEl.textContent = form.dataset.confirmTitle || 'Confirm Action';
                confirmMessageEl.textContent = form.dataset.confirmMessage || 'Are you sure you want to continue?';
                confirmSubmitBtn.textContent = form.dataset.confirmButton || 'Confirm';
                confirmSubmitBtn.className = form.dataset.confirmButtonClass || 'btn btn-pup-primary px-4';
                confirmModal.show();
            });
        });

        confirmSubmitBtn.addEventListener('click', () => {
            if (!pendingConfirmForm) return;
            pendingConfirmForm.dataset.confirmed = 'true';
            confirmSubmitBtn.disabled = true;
            confirmSubmitBtn.innerHTML = '<span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>Processing...';
            confirmModal.hide();
            pendingConfirmForm.requestSubmit();
        });

        confirmModalEl.addEventListener('hidden.bs.modal', () => {
            pendingConfirmForm = null;
            confirmSubmitBtn.disabled = false;
            confirmSubmitBtn.textContent = 'Confirm';
            confirmSubmitBtn.className = 'btn btn-pup-primary px-4';
        });
    }

    // 1. Toast Notification Manager
    window.showToast = function(title, message, type = 'info') {
        const container = document.getElementById('toast-container');
        if (!container) return;
        
        let bgClass = 'bg-primary';
        let icon = '<i class="fa-solid fa-circle-info me-2"></i>';
        
        if (type === 'success') {
            bgClass = 'bg-success';
            icon = '<i class="fa-solid fa-circle-check me-2"></i>';
        } else if (type === 'error' || type === 'danger') {
            bgClass = 'bg-danger';
            icon = '<i class="fa-solid fa-circle-xmark me-2"></i>';
        } else if (type === 'warning') {
            bgClass = 'bg-warning';
            icon = '<i class="fa-solid fa-triangle-exclamation me-2"></i>';
        }
        
        // If title is "System Alert", replace title with the icon itself
        const toastId = 'toast-' + Date.now();
        const toast = document.createElement('div');
        toast.id = toastId;
        toast.className = `toast align-items-center text-white ${bgClass} border-0 show animated-fade-in`;
        toast.setAttribute('role', 'alert');
        toast.setAttribute('aria-live', 'assertive');
        toast.setAttribute('aria-atomic', 'true');
        toast.style.marginBottom = '10px';

        const wrap = document.createElement('div');
        wrap.className = 'd-flex';
        const body = document.createElement('div');
        body.className = 'toast-body d-flex align-items-center';

        if (title === 'System Alert') {
            const iconEl = document.createElement('i');
            iconEl.className = icon.match(/class="([^"]+)"/)?.[1] || 'fa-solid fa-circle-info me-2';
            body.appendChild(iconEl);
            body.appendChild(document.createTextNode(message));
        } else {
            const titleEl = document.createElement('strong');
            titleEl.textContent = title;
            body.appendChild(titleEl);
            body.appendChild(document.createTextNode(`: ${message}`));
        }

        const closeBtn = document.createElement('button');
        closeBtn.type = 'button';
        closeBtn.className = 'btn-close btn-close-white me-2 m-auto';
        closeBtn.setAttribute('data-bs-dismiss', 'toast');
        closeBtn.setAttribute('aria-label', 'Close');
        closeBtn.addEventListener('click', () => toast.remove());

        wrap.append(body, closeBtn);
        toast.appendChild(wrap);
        container.appendChild(toast);
        
        // Auto-dismiss after 5 seconds
        setTimeout(() => {
            const toastElement = document.getElementById(toastId);
            if (toastElement) {
                toastElement.classList.remove('show');
                setTimeout(() => toastElement.remove(), 300);
            }
        }, 5000);
    };

    // 2. Collapsible Admin Sidebar Preference
    const sidebarToggle = document.getElementById('sidebar-toggle');
    const sidebar = document.getElementById('dash-sidebar');
    const mainContent = document.getElementById('dash-main-content');
    const sidebarIcon = document.getElementById('sidebar-toggle-icon');
    
    if (sidebar && mainContent) {
        const setSidebarState = (collapse) => {
            if (collapse) {
                sidebar.classList.add('collapsed');
                mainContent.classList.add('expanded');
                if (sidebarIcon) {
                    sidebarIcon.classList.remove('fa-angles-left');
                    sidebarIcon.classList.add('fa-angles-right');
                }
            } else {
                sidebar.classList.remove('collapsed');
                mainContent.classList.remove('expanded');
                if (sidebarIcon) {
                    sidebarIcon.classList.remove('fa-angles-right');
                    sidebarIcon.classList.add('fa-angles-left');
                }
            }
            localStorage.setItem('sidebar-collapsed', collapse);
        };
        
        // Load preference
        const isCollapsed = localStorage.getItem('sidebar-collapsed') === 'true';
        setSidebarState(isCollapsed);
        
        if (sidebarToggle) {
            sidebarToggle.addEventListener('click', () => {
                const currentlyCollapsed = sidebar.classList.contains('collapsed');
                setSidebarState(!currentlyCollapsed);
            });
        }
    }

    // 3. Floating Chatbot Interactions
    const chatToggle = document.getElementById('chatbot-toggle');
    const chatWindow = document.getElementById('chatbot-window');
    const chatClose = document.getElementById('chatbot-close');
    const chatSend = document.getElementById('chatbot-send');
    const chatInput = document.getElementById('chatbot-input');
    const chatBody = document.getElementById('chatbot-body');
    const chatQuickActions = document.getElementById('chatbot-quick-actions');
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '';
    
    let chatHistory = [];
    const defaultChatSuggestions = [
        'Available rooms',
        'My status',
        'Requirements'
    ];
    const suggestionPrompts = {
        'Available rooms': 'Show available rooms tomorrow 10 AM to 12 PM',
        'My status': 'Check my reservation status',
        'Requirements': 'What are the reservation requirements?',
        'Reservation requirements': 'What are the reservation requirements?',
        'Available rooms tomorrow': 'Show available rooms tomorrow 10 AM to 12 PM',
        'Available AVR tomorrow 10 AM': 'Is AVR available tomorrow 10 AM to 11 AM?',
        'Today summary': 'Summarize today reservations',
        'Pending approvals': 'How many pending approvals today?',
        'Most requested facility': 'What is the most requested facility this month?',
        'How to reserve': 'How do I reserve a facility?'
    };
    
    if (chatToggle && chatWindow && chatClose) {
        chatToggle.addEventListener('click', () => {
            if (chatWindow.style.display === 'none' || chatWindow.style.display === '') {
                chatWindow.style.display = 'flex';
                chatInput.focus();
                renderChatSuggestions(defaultChatSuggestions);
                // Send initial greeting if empty
                if (chatBody.children.length === 0) {
                    appendBotMessage("Mabuhay! I can check room availability, explain requirements, review reservation status, and summarize admin activity.");
                }
            } else {
                chatWindow.style.display = 'none';
            }
        });
        
        chatClose.addEventListener('click', () => {
            chatWindow.style.display = 'none';
        });
    }
    
    function appendBotMessage(text) {
        if (!chatBody) return;
        const msgDiv = document.createElement('div');
        msgDiv.className = 'chatbot-msg chatbot-msg-bot';
        msgDiv.innerHTML = text; // Supports bold/format
        chatBody.appendChild(msgDiv);
        chatBody.scrollTop = chatBody.scrollHeight;
        chatHistory.push({role: 'assistant', content: text});
    }
    
    function appendUserMessage(text) {
        if (!chatBody) return;
        const msgDiv = document.createElement('div');
        msgDiv.className = 'chatbot-msg chatbot-msg-user';
        msgDiv.innerText = text;
        chatBody.appendChild(msgDiv);
        chatBody.scrollTop = chatBody.scrollHeight;
        chatHistory.push({role: 'user', content: text});
    }

    function renderChatSuggestions(suggestions) {
        if (!chatQuickActions) return;
        const items = Array.isArray(suggestions) && suggestions.length ? suggestions : defaultChatSuggestions;
        chatQuickActions.innerHTML = '';
        items.slice(0, 4).forEach(label => {
            const btn = document.createElement('button');
            btn.type = 'button';
            btn.className = 'chatbot-chip';
            btn.textContent = label;
            btn.addEventListener('click', () => {
                if (!chatInput) return;
                chatInput.value = suggestionPrompts[label] || label;
                sendChat();
            });
            chatQuickActions.appendChild(btn);
        });
    }
    
    function sendChat() {
        if (!chatInput) return;
        const text = chatInput.value.trim();
        if (!text) return;
        
        appendUserMessage(text);
        chatInput.value = '';
        
        // Show typing indicator
        const typingDiv = document.createElement('div');
        typingDiv.className = 'chatbot-msg chatbot-msg-bot typing-indicator';
        typingDiv.setAttribute('aria-label', 'PUP AI is typing');
        typingDiv.innerHTML = '<span class="typing-dot"></span><span class="typing-dot"></span><span class="typing-dot"></span>';
        chatBody.appendChild(typingDiv);
        chatBody.scrollTop = chatBody.scrollHeight;
        
        // Call API
        fetch('/ai/chat', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'X-CSRFToken': csrfToken },
            body: JSON.stringify({ message: text, history: chatHistory })
        })
        .then(res => res.json())
        .then(data => {
            typingDiv.remove();
            if (data.response) {
                appendBotMessage(data.response);
                renderChatSuggestions(data.suggestions);
            } else {
                appendBotMessage("Sorry, I encountered an issue. Please try again later.");
                renderChatSuggestions(defaultChatSuggestions);
            }
        })
        .catch(err => {
            typingDiv.remove();
            appendBotMessage("Connection failed. Please check your network.");
            renderChatSuggestions(defaultChatSuggestions);
        });
    }
    
    if (chatSend && chatInput) {
        chatSend.addEventListener('click', sendChat);
        chatInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                sendChat();
            }
        });
    }

    // Helper function to format phone numbers on input
    function formatPhoneNumber(input) {
        let val = input.value.replace(/\D/g, '');
        if (val.length > 11) {
            val = val.slice(0, 11);
        }
        let formatted = '';
        if (val.length <= 4) {
            formatted = val;
        } else if (val.length <= 7) {
            formatted = val.slice(0, 4) + ' ' + val.slice(4);
        } else {
            formatted = val.slice(0, 4) + ' ' + val.slice(4, 7) + ' ' + val.slice(7);
        }
        input.value = formatted;
    }

    // Helper to format proper nouns/names to Last, First M.
    function formatToProperNoun(value) {
        if (!value) return '';
        let parts = value.split(',');
        let formatWord = (w) => w ? w.charAt(0).toUpperCase() + w.slice(1).toLowerCase() : '';
        
        let lastName = parts[0] ? parts[0].trim().split(/\s+/).map(formatWord).join(' ') : '';
        let firstMid = '';
        
        if (parts.length > 1) {
            let rest = parts.slice(1).join(',').trim();
            if (rest) {
                let words = rest.split(/\s+/);
                let lastWord = words[words.length - 1];
                if (lastWord.length === 1 || (lastWord.length === 2 && lastWord.endsWith('.'))) {
                    words[words.length - 1] = lastWord.charAt(0).toUpperCase() + '.';
                }
                firstMid = words.map(w => {
                    if (w.endsWith('.') && w.length === 2) return w.toUpperCase();
                    return formatWord(w);
                }).join(' ');
            }
        }
        
        if (firstMid) {
            return `${lastName}, ${firstMid}`;
        }
        return lastName;
    }

    // Attach global listener to any contact number field
    const contactNumFields = document.querySelectorAll('input[name="contact_number"], #contact_number');
    contactNumFields.forEach(field => {
        field.addEventListener('input', (e) => {
            let cursor = field.selectionStart;
            let oldLen = field.value.length;
            formatPhoneNumber(field);
            let newLen = field.value.length;
            let diff = newLen - oldLen;
            let newPos = cursor + diff;
            if (diff > 0 && (newPos === 5 || newPos === 9)) {
                newPos++;
            }
            field.setSelectionRange(newPos, newPos);
        });
    });

    // 4. Real-Time Student Registration Validations
    const regForm = document.getElementById('registration-form');
    if (regForm) {
        const fullName = document.getElementById('full_name');
        const email = document.getElementById('email');
        const contactNum = document.getElementById('contact_number');
        const studNum = document.getElementById('student_number');
        const prog = document.getElementById('program');
        const section = document.getElementById('year_section');
        const pass = document.getElementById('password');
        const cpass = document.getElementById('confirm_password');
        const regBtn = document.getElementById('register-submit-btn');

        const validators = {
            full_name: () => {
                if (fullName.dataset.serverInvalid === "true") {
                    return false;
                }
                const val = fullName.value.trim();
                const isValid = /^[A-Za-z\s\-'\.]+,(\s[A-Za-z\s\-'\.]+)+$/.test(val);
                setFieldState(fullName, isValid, "Name should follow the format: Last Name, First Name (e.g., Francisco, Juan S. or Aguilon, Kate Heart).");
                return isValid;
            },
            email: () => {
                if (email.dataset.serverInvalid === "true") {
                    return false;
                }
                const val = email.value.trim();
                const re = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
                const isFormatValid = re.test(val);
                const isDomainValid = val.endsWith('@gmail.com') || val.endsWith('@iskolarngbayan.pup.edu.ph');
                const isValid = isFormatValid && isDomainValid;
                setFieldState(email, isValid, "Email should be valid.");
                return isValid;
            },
            contact_number: () => {
                if (contactNum.dataset.serverInvalid === "true") {
                    return false;
                }
                const re = /^09\d{2} \d{3} \d{4}$/;
                const isValid = re.test(contactNum.value.trim());
                setFieldState(contactNum, isValid, "Contact number should be valid.");
                return isValid;
            },
            student_number: () => {
                if (studNum.dataset.serverInvalid === "true") {
                    return false;
                }
                const re = /^\d{4}-\d{5}-PQ-[0-9]$/;
                const isValid = re.test(studNum.value.trim());
                setFieldState(studNum, isValid, "Student number must follow the format: YYYY-XXXXX-PQ-0 or YYYY-XXXXX-PQ-1.");
                return isValid;
            },
            program: () => {
                if (prog.dataset.serverInvalid === "true") {
                    return false;
                }
                const isValid = prog.value !== "";
                setFieldState(prog, isValid, "Please select your program/course.");
                return isValid;
            },
            year_section: () => {
                if (section.dataset.serverInvalid === "true") {
                    return false;
                }
                const isValid = section.value !== "";
                setFieldState(section, isValid, "Please select your year & section.");
                return isValid;
            },
            password: () => {
                if (pass.dataset.serverInvalid === "true") {
                    return false;
                }
                const val = pass.value;
                const lenVal = val.length >= 8;
                const specVal = /[A-Z]/.test(val) && /[a-z]/.test(val) && /\d/.test(val) && /[@$!%*?&]/.test(val);
                const isValid = lenVal && specVal;
                setFieldState(pass, isValid, "Password must be at least 8 characters and include a lowercase letter, an uppercase letter, a number, and a special character.");
                return isValid;
            },
            confirm_password: () => {
                if (cpass.dataset.serverInvalid === "true") {
                    return false;
                }
                const isValid = cpass.value === pass.value && cpass.value !== "";
                setFieldState(cpass, isValid, "Confirm Password must match Password.");
                return isValid;
            }
        };

        function setFieldState(input, isValid, errorMessage) {
            const feedbackValid = input.closest('.pup-form-group').querySelector('.pup-input-feedback-valid');
            const feedbackInvalid = input.closest('.pup-form-group').querySelector('.pup-input-feedback-invalid');
            
            if (isValid) {
                input.classList.remove('is-invalid');
                input.classList.add('is-valid');
                if (feedbackValid) feedbackValid.style.display = 'block';
                if (feedbackInvalid) feedbackInvalid.style.display = 'none';
            } else {
                input.classList.remove('is-valid');
                input.classList.add('is-invalid');
                if (feedbackValid) feedbackValid.style.display = 'none';
                if (feedbackInvalid) {
                    feedbackInvalid.innerText = errorMessage;
                    feedbackInvalid.style.display = 'block';
                }
            }
        }

        function validateAll() {
            let formValid = true;
            for (const key in validators) {
                // If field has not been touched, don't show invalid but keep button disabled
                const field = document.getElementById(key);
                const isTouched = field && (field.value !== "" || field.classList.contains('is-valid') || field.classList.contains('is-invalid'));
                
                let fieldValid = false;
                if (isTouched) {
                    fieldValid = validators[key]();
                } else {
                    // Check if it naturally validates anyway without showing UI errors
                    if (key === 'confirm_password') {
                        fieldValid = cpass.value === pass.value && cpass.value !== "";
                    } else if (key === 'program' || key === 'year_section') {
                        fieldValid = document.getElementById(key).value !== "";
                    } else {
                        fieldValid = validators[key] ? false : true;
                    }
                }
                
                if (!fieldValid) formValid = false;
            }
            
            regBtn.disabled = !formValid;
        }

        // Initialize Sentence Case formatting on name fields blur
        [fullName].forEach(input => {
            if (input) {
                input.addEventListener('blur', () => {
                    input.value = formatToProperNoun(input.value);
                    validateAll();
                });
            }
        });

        // Attach listeners
        [fullName, email, contactNum, studNum, pass, cpass].forEach(input => {
            if (input) {
                input.addEventListener('input', () => {
                    input.classList.add('touched');
                    delete input.dataset.serverInvalid;
                    validateAll();
                });
                input.addEventListener('blur', () => {
                    input.classList.add('touched');
                    validateAll();
                });
            }
        });
        
        [prog, section].forEach(select => {
            if (select) {
                select.addEventListener('change', () => {
                    select.classList.add('touched');
                    delete select.dataset.serverInvalid;
                    validateAll();
                });
            }
        });

        // Initialize state
        validateAll();
    }
});
