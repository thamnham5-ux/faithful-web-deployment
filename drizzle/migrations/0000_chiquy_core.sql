CREATE TYPE public.app_role AS ENUM ('admin','user');
CREATE TABLE public.user_roles (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL, role public.app_role NOT NULL, UNIQUE(user_id,role));
GRANT SELECT ON public.user_roles TO authenticated;
GRANT ALL ON public.user_roles TO service_role;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role public.app_role) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$ SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id=_user_id AND role=_role) $$;
CREATE POLICY "own roles" ON public.user_roles FOR SELECT TO authenticated USING (user_id = auth.uid());

CREATE TABLE public.profiles (id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE, email text NOT NULL, name text NOT NULL DEFAULT '', fb text NOT NULL DEFAULT '', created_at timestamptz NOT NULL DEFAULT now());
GRANT SELECT, UPDATE ON public.profiles TO authenticated;
GRANT ALL ON public.profiles TO service_role;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "read own or admin" ON public.profiles FOR SELECT TO authenticated USING (id = auth.uid() OR public.has_role(auth.uid(),'admin'));
CREATE POLICY "update own" ON public.profiles FOR UPDATE TO authenticated USING (id = auth.uid()) WITH CHECK (id = auth.uid());

CREATE OR REPLACE FUNCTION public.handle_new_user() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.profiles(id,email,name,fb) VALUES (NEW.id, lower(NEW.email), left(coalesce(NEW.raw_user_meta_data->>'name',''),120), left(coalesce(NEW.raw_user_meta_data->>'fb',''),300));
  INSERT INTO public.user_roles(user_id,role) VALUES (NEW.id,'user');
  IF lower(NEW.email) = 'tanchinhuquy@gmail.com' THEN INSERT INTO public.user_roles(user_id,role) VALUES (NEW.id,'admin'); END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE TABLE public.demos (code text PRIMARY KEY, name text NOT NULL, service text NOT NULL DEFAULT 'web', tags text[] NOT NULL DEFAULT '{}', visual int NOT NULL DEFAULT 1, url text NOT NULL DEFAULT '', support text[] NOT NULL DEFAULT '{}', status text NOT NULL DEFAULT 'available' CHECK (status IN ('available','slotout')), sort int NOT NULL DEFAULT 0, created_at timestamptz NOT NULL DEFAULT now());
GRANT SELECT ON public.demos TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.demos TO authenticated;
GRANT ALL ON public.demos TO service_role;
ALTER TABLE public.demos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public read demos" ON public.demos FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "admin insert demos" ON public.demos FOR INSERT TO authenticated WITH CHECK (public.has_role(auth.uid(),'admin'));
CREATE POLICY "admin update demos" ON public.demos FOR UPDATE TO authenticated USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));
CREATE POLICY "admin delete demos" ON public.demos FOR DELETE TO authenticated USING (public.has_role(auth.uid(),'admin'));

CREATE TABLE public.orders (id text PRIMARY KEY, user_id uuid NOT NULL DEFAULT auth.uid(), account text NOT NULL, name text NOT NULL DEFAULT '', fb text NOT NULL DEFAULT '', items jsonb NOT NULL DEFAULT '[]', total numeric NOT NULL DEFAULT 0, status text NOT NULL DEFAULT 'received' CHECK (status IN ('received','processing','accepted','replied','done','rejected')), created_at timestamptz NOT NULL DEFAULT now(), due_at timestamptz NOT NULL DEFAULT now() + interval '7 days');
GRANT SELECT, INSERT, UPDATE ON public.orders TO authenticated;
GRANT ALL ON public.orders TO service_role;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "read own or admin orders" ON public.orders FOR SELECT TO authenticated USING (user_id = auth.uid() OR public.has_role(auth.uid(),'admin'));
CREATE POLICY "create own order" ON public.orders FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid() AND status = 'received');
CREATE POLICY "admin update orders" ON public.orders FOR UPDATE TO authenticated USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));

INSERT INTO public.demos(code,name,service,tags,visual,url,support,status,sort) VALUES
('CQ-W-041','Nhật Triều Kỷ','web',ARRAY['codai','tanthe'],10,'https://nhattrieukyy.netlify.app',ARRAY['Thay đổi nội dung toàn bộ','Thêm tối đa 2 trang và 1 chức năng (vd: vòng quay)','Thay đổi 30% bố cục, theme (vd: trang chủ)'],'available',1),
('CQ-W-042','Nam Phương','web',ARRAY['codai','cungdinh'],11,'https://namphuongtrieu.netlify.app/',ARRAY['Thay đổi nội dung toàn bộ','Thêm tối đa 2 trang và 2 chức năng (vd: vòng quay)','Thay đổi 30% bố cục, theme (vd: trang chủ)'],'available',2),
('CQ-W-043','Đắc Bách Triều','web',ARRAY['codai','cungdinh','quandau'],12,'https://dacbachtrieuu.netlify.app/',ARRAY['Thay đổi nội dung toàn bộ','Thêm tối đa 2 trang và 2 chức năng (vd: vòng quay)','Thay đổi 30% bố cục, theme (vd: trang chủ)'],'available',3),
('CQ-W-044','Tân Nguyên Niên','web',ARRAY['tinhte','trungtoc'],13,'https://radiant-churros-613cc6.netlify.app/',ARRAY['Thay đổi nội dung toàn bộ','Thêm tối đa 1 trang và 3 chức năng (vd: vòng quay)','Thay đổi 30% bố cục, theme (vd: trang chủ)','Lưu trữ dữ liệu người chơi và tài sản'],'available',4),
('CQ-W-045','Tinh Chương Mang Hải','web',ARRAY['tinhte','giaitri'],14,'https://tinhchuongmanghai.netlify.app/',ARRAY['Thay đổi nội dung toàn bộ','Thêm tối đa 1 trang và 2 chức năng (vd: vòng quay)','Thay đổi 30% bố cục, theme (vd: trang chủ)','Lưu trữ dữ liệu người chơi và tài sản'],'available',5),
('CQ-W-046','Hồng Tuyến','web',ARRAY['codai','maimoi'],15,'',ARRAY['Thay đổi nội dung toàn bộ','Thêm tối đa 1 trang và 2 chức năng (vd: vòng quay)','Thay đổi 30% bố cục, theme (vd: trang chủ)','Lưu trữ dữ liệu người chơi và tài sản'],'available',6);