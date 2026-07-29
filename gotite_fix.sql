use openmrs;

UPDATE gotite.global_property
SET property_value = '1'
WHERE property = 'registrationcore.identifierSourceId'
  AND (property_value IS NULL OR property_value = '');

UPDATE gotite.idgen_seq_id_gen
SET next_sequence_value = 10000
WHERE id = 1
  AND next_sequence_value = -1;


UPDATE gotite.global_property
SET property_value = 'registrationcore.BasicPatientNameSearch'
WHERE property = 'registrationcore.patientNameSearch';


UPDATE gotite.global_property
SET property_value = 'Numero de Telefone, Numero de Telefone 2, Identificador definido localmente 01, Tipo de Paciente'
WHERE property = 'patient.viewingAttributeTypes';


UPDATE gotite.global_property
SET property_value = 'true'
WHERE property = 'registrationcore.started';


