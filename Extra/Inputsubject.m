function [sub] = Inputsubject(sub)

            prompt = {...
                'Numero voluntario',...
                'Numero sessao',...
                'Genero (M/F/NB)',...
                'Idade',...
                'Mao dominante (E/D)',...
                'Olho dominante (E/D)',...
                'Correcao visao (S/N)',...
                'Apresentação estímulos'};
            
            defanswer = {sub.id, sub.ses, '', '', '', '', '',sub.RDK_color};
            answer = inputdlg(prompt, '', [1 22], defanswer);
            
            sub.id = answer{1};
            sub.id_num = str2double(answer{1});
            
            sub.ses = answer{2};
            sub.ses_num = str2double(answer{2});
            
            sub.gender = answer{3};
            
            sub.age = answer{4};
            
            sub.hand = answer{5};
            
            sub.eye = answer{6};
            if sub.eye == 'E'; sub.eye_num = 1;
            elseif sub.eye == 'D'; sub.eye_num = 2;
            else; error('Olho dominante inválido.');
            end
            
            sub.eye_corr = answer{7};
        
        
end