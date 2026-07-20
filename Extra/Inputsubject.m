function [sub] = Inputsubject(sub)

            prompt = {...
                'Numero voluntario',...                
                'Genero (M/F/NB)',...
                'Idade',...
                'Mao dominante (E/D)',...
                'Olho dominante (E/D)',...
                'Correcao visao (S/N)'};
            
            defanswer = {sub.id, '', '', '', '', ''};
            answer = inputdlg(prompt, '', [1 22], defanswer);
            
            sub.id = answer{1};
            sub.id_num = str2double(answer{1});
            
            sub.gender = answer{2};
            
            sub.age = answer{3};
            
            sub.hand = answer{4};
            
            sub.eye = answer{5};
            if sub.eye == 'E'; sub.eye_num = 1;
            elseif sub.eye == 'D'; sub.eye_num = 2;
            else; error('Olho dominante inválido.');
            end
            
            sub.eye_corr = answer{6};
        
        
end