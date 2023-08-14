ALTER TABLE usuario ALTER COLUMN id TYPE bigint;
CREATE SEQUENCE usuario_id_seq START 1;
ALTER TABLE usuario ALTER COLUMN id SET DEFAULT nextval('usuario_id_seq'::regclass);

